//
//  AO3Cache.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 29.09.2026.
//

import Foundation
import CryptoKit

public actor AO3Cache {
    
    private final class MemoryEntry: NSObject {
        let expirationDate: Date
        let payload: Data
        
        init(expirationDate: Date, payload: Data) {
            self.expirationDate = expirationDate
            self.payload = payload
        }
    }
    
    private struct DiskEntry: Codable {
        let expirationDate: Date
        let payload: Data
    }
    
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    
    private var trackedKeys: Set<String> = []
    private var indexURL: URL { diskCacheURL.appendingPathComponent("AO3Cache_Index.json") }

    
    private let memoryCache = NSCache<NSString, MemoryEntry>()
    
    public let defaultTTL: TimeInterval
    public let storageStrategy: AO3CacheStrategy
    public let expirationStrategy: AO3CacheExpirationStrategy
    public let diskByteLimit: Int
    
    /// Initializes the caching engine.
    /// - Parameters:
    ///   - memoryCountLimit: Maximum number of objects in RAM. 0 means no limit.
    ///   - diskByteLimit: Maximum bytes allowed on disk. 0 means no limit.
    public init(
        diskDirectoryName: String = "AO3KitCache",
        defaultTTL: TimeInterval = 360,
        storageStrategy: AO3CacheStrategy = .both,
        expirationStrategy: AO3CacheExpirationStrategy = .keepUntilReplaced,
        memoryCountLimit: Int = 100,
        diskByteLimit: Int = 50 * 1024 * 1024
    ) {
        self.defaultTTL = defaultTTL
        self.storageStrategy = storageStrategy
        self.expirationStrategy = expirationStrategy
        self.diskByteLimit = diskByteLimit
        
        self.memoryCache.countLimit = memoryCountLimit
        
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = urls[0].appendingPathComponent(diskDirectoryName)
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        self.diskCacheURL = cacheDir
        print("[AO3Kit] Cache Directory: \(cacheDir.absoluteString)")
        
        if let data = try? Data(contentsOf: diskCacheURL.appendingPathComponent("AO3Cache_Index.json")),
           let savedKeys = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.trackedKeys = savedKeys
        }

    }
    
    // MARK: - Write
    
    public func set<T: Codable & Sendable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) throws {
        let expiration = Date().addingTimeInterval(ttl ?? defaultTTL)
        let payload = try JSONEncoder().encode(value)
        
        if storageStrategy == .memoryOnly || storageStrategy == .both {
            let entry = MemoryEntry(expirationDate: expiration, payload: payload)
            memoryCache.setObject(entry, forKey: key as NSString)
            
            if trackedKeys.insert(key).inserted {
                try? JSONEncoder().encode(trackedKeys).write(to: indexURL)
            }
        }
        
        if storageStrategy == .diskOnly || storageStrategy == .both {
            let diskEntry = DiskEntry(expirationDate: expiration, payload: payload)
            let fileURL = diskCacheURL.appendingPathComponent(safeFileName(for: key))
            let entryData = try JSONEncoder().encode(diskEntry)
            try? entryData.write(to: fileURL)
            
            Task {
                self.enforceDiskLimit()
            }
        }

    }
    
    // MARK: - Read
    
    public func get<T: Codable & Sendable>(forKey key: String, as type: T.Type = T.self) throws -> AO3CacheResponse<T> {
        let safeName = safeFileName(for: key)
        var foundPayload: Data? = nil
        var foundExpiration: Date? = nil
        
        if (storageStrategy == .both || storageStrategy == .memoryOnly),
           let memoryEntry = memoryCache.object(forKey: key as NSString) {
            foundPayload = memoryEntry.payload
            foundExpiration = memoryEntry.expirationDate
        } else if (storageStrategy == .both || storageStrategy == .diskOnly) {
            var fileURL = diskCacheURL.appendingPathComponent(safeName)
            if let entryData = try? Data(contentsOf: fileURL),
               let diskEntry = try? JSONDecoder().decode(DiskEntry.self, from: entryData) {
                
                foundPayload = diskEntry.payload
                foundExpiration = diskEntry.expirationDate
                
                if storageStrategy == .both {
                    let memEntry = MemoryEntry(expirationDate: diskEntry.expirationDate, payload: diskEntry.payload)
                    memoryCache.setObject(memEntry, forKey: key as NSString)
                }
                
                var resourceValues = URLResourceValues()
                resourceValues.contentAccessDate = Date()
                try? fileURL.setResourceValues(resourceValues)
            }
        }

        
        guard let payload = foundPayload, let expiration = foundExpiration else {
            return AO3CacheResponse(data: nil, state: .notFound)
        }
        
        let decodedData = try JSONDecoder().decode(T.self, from: payload)
        
        if expiration > Date() {
            return AO3CacheResponse(data: decodedData, state: .upToDate)
        } else {
            if expirationStrategy == .discard {
                delete(forKey: key)
                return AO3CacheResponse(data: decodedData, state: .discarded)
            }
            return AO3CacheResponse(data: decodedData, state: .expired)
        }
    }
    
    // MARK: - Maintenance & Deletion
    
    public func delete(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        let fileURL = diskCacheURL.appendingPathComponent(safeFileName(for: key))
        try? fileManager.removeItem(at: fileURL)
    }
    
    public func clearAll() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        self.trackedKeys.removeAll()
        try? fileManager.removeItem(at: indexURL)
    }
    
    /// Sweeps the disk cache and aggressively deletes any file whose expiration date has passed.
    public func purgeExpired() {
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil) else { return }
        
        for fileURL in fileURLs {
            guard let data = try? Data(contentsOf: fileURL),
                  let entry = try? JSONDecoder().decode(DiskEntry.self, from: data) else { continue }
            
            if entry.expirationDate < Date() {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    /// Trims the disk cache down to the `diskByteLimit` by evicting the Least Recently Used (LRU) files.
    private func enforceDiskLimit() {
        guard diskByteLimit > 0 else { return }
        
        let keys: [URLResourceKey] = [.fileSizeKey, .contentAccessDateKey]
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: keys) else { return }
        
        var totalSize = 0
        var cacheFiles: [(url: URL, size: Int, accessDate: Date)] = []
        
        for url in fileURLs {
            if let resources = try? url.resourceValues(forKeys: Set(keys)),
               let size = resources.fileSize,
               let accessDate = resources.contentAccessDate {
                totalSize += size
                cacheFiles.append((url: url, size: size, accessDate: accessDate))
            }
        }
        
        guard totalSize > diskByteLimit else { return }
        
        cacheFiles.sort { $0.accessDate < $1.accessDate }
        
        for file in cacheFiles {
            try? fileManager.removeItem(at: file.url)
            totalSize -= file.size
            if totalSize <= diskByteLimit { break }
        }
    }
    
    private func safeFileName(for key: String) -> String {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Invalidates all cached items whose keys contain the specified substring.
    public func invalidate(containing substring: String) {
        let matchingKeys = trackedKeys.filter { $0.localizedStandardContains(substring) }
        
        for key in matchingKeys {
            memoryCache.removeObject(forKey: key as NSString)
            let fileURL = diskCacheURL.appendingPathComponent(safeFileName(for: key))
            try? fileManager.removeItem(at: fileURL)
            trackedKeys.remove(key)
        }
        
        if !matchingKeys.isEmpty {
            try? JSONEncoder().encode(trackedKeys).write(to: indexURL)
        }
    }
    
    /// Invalidates all cached items whose keys start with the specified prefix.
    public func invalidate(withPrefix prefix: String) {
        let matchingKeys = trackedKeys.filter { $0.hasPrefix(prefix) }
        
        for key in matchingKeys {
            memoryCache.removeObject(forKey: key as NSString)
            let fileURL = diskCacheURL.appendingPathComponent(safeFileName(for: key))
            try? fileManager.removeItem(at: fileURL)
            trackedKeys.remove(key)
        }
        
        if !matchingKeys.isEmpty {
            try? JSONEncoder().encode(trackedKeys).write(to: indexURL)
        }
    }

}

