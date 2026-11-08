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
        var expirationDate: Date
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
    
    private static let indexFileName = "AO3Cache_Index.json"
    private var indexURL: URL { diskCacheURL.appendingPathComponent(Self.indexFileName) }
    
    private var trackedKeys: Set<String> = []
    private var fileNameToKey: [String: String] = [:]
    
    private let memoryCache = NSCache<NSString, MemoryEntry>()
    
    public let defaultTTL: TimeInterval
    public let storageStrategy: AO3CacheStrategy
    public let expirationStrategy: AO3CacheExpirationStrategy
    public let diskByteLimit: Int
    
    private var usesMemory: Bool { storageStrategy == .memoryOnly || storageStrategy == .both }
    private var usesDisk: Bool { storageStrategy == .diskOnly || storageStrategy == .both }
    
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
        self.diskCacheURL = cacheDir
        
        if storageStrategy != .memoryOnly {
            if !fileManager.fileExists(atPath: cacheDir.path) {
                try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }
            
            let savedIndexURL = cacheDir.appendingPathComponent(Self.indexFileName)
            if let data = try? Data(contentsOf: savedIndexURL),
               let savedKeys = try? JSONDecoder().decode(Set<String>.self, from: data) {
                self.trackedKeys = savedKeys
                for key in savedKeys {
                    let hash = Self.computeSafeFileName(for: key)
                    self.fileNameToKey[hash] = key
                }
            }
        }
    }
    
    // MARK: - Write
    
    public func set<T: Codable & Sendable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) throws {
        let expiration = Date().addingTimeInterval(ttl ?? defaultTTL)
        let payload = try JSONEncoder().encode(value)
        let safeName = safeFileName(for: key)
        
        if trackedKeys.insert(key).inserted {
            fileNameToKey[safeName] = key
            persistIndexIfNeeded()
        }
        
        if usesMemory {
            let entry = MemoryEntry(expirationDate: expiration, payload: payload)
            memoryCache.setObject(entry, forKey: key as NSString)
        }
        
        if usesDisk {
            let diskEntry = DiskEntry(expirationDate: expiration, payload: payload)
            let fileURL = diskCacheURL.appendingPathComponent(safeName)
            let entryData = try JSONEncoder().encode(diskEntry)
            try? entryData.write(to: fileURL)
            
            enforceDiskLimit()
        }
    }
    
    // MARK: - Read
    
    public func get<T: Codable & Sendable>(forKey key: String, as type: T.Type = T.self) throws -> AO3CacheResponse<T> {
        let safeName = safeFileName(for: key)
        var foundPayload: Data? = nil
        var foundExpiration: Date? = nil
        
        if usesMemory, let memoryEntry = memoryCache.object(forKey: key as NSString) {
            foundPayload = memoryEntry.payload
            foundExpiration = memoryEntry.expirationDate
        } else if usesDisk {
            var fileURL = diskCacheURL.appendingPathComponent(safeName)
            if let entryData = try? Data(contentsOf: fileURL),
               let diskEntry = try? JSONDecoder().decode(DiskEntry.self, from: entryData) {
                
                foundPayload = diskEntry.payload
                foundExpiration = diskEntry.expirationDate
                
                if usesMemory {
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
        let safeName = safeFileName(for: key)
        memoryCache.removeObject(forKey: key as NSString)
        
        if usesDisk {
            let fileURL = diskCacheURL.appendingPathComponent(safeName)
            try? fileManager.removeItem(at: fileURL)
        }
        
        fileNameToKey.removeValue(forKey: safeName)
        if trackedKeys.remove(key) != nil {
            persistIndexIfNeeded()
        }
    }
    
    public func clearAll() {
        memoryCache.removeAllObjects()
        trackedKeys.removeAll()
        fileNameToKey.removeAll()
        
        if usesDisk {
            try? fileManager.removeItem(at: diskCacheURL)
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
    /// Sweeps the disk cache and deletes any file whose expiration date has passed.
    public func purgeExpired() {
        guard usesDisk,
              let fileURLs = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil) else { return }
        
        var didRemoveKey = false
        let now = Date()
        
        for fileURL in fileURLs where fileURL.lastPathComponent != Self.indexFileName {
            guard let data = try? Data(contentsOf: fileURL),
                  let entry = try? JSONDecoder().decode(DiskEntry.self, from: data) else { continue }
            
            if entry.expirationDate < now {
                try? fileManager.removeItem(at: fileURL)
                if let key = fileNameToKey.removeValue(forKey: fileURL.lastPathComponent) {
                    memoryCache.removeObject(forKey: key as NSString)
                    trackedKeys.remove(key)
                    didRemoveKey = true
                }
            }
        }
        
        if didRemoveKey {
            persistIndexIfNeeded()
        }
    }
    
    /// Trims the disk cache down to `diskByteLimit` by evicting Least Recently Used (LRU) files.
    private func enforceDiskLimit() {
        guard usesDisk, diskByteLimit > 0 else { return }
        
        let keys: [URLResourceKey] = [.fileSizeKey, .contentAccessDateKey]
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: keys) else { return }
        
        var totalSize = 0
        var cacheFiles: [(url: URL, size: Int, accessDate: Date)] = []
        
        for url in fileURLs where url.lastPathComponent != Self.indexFileName {
            if let resources = try? url.resourceValues(forKeys: Set(keys)),
               let size = resources.fileSize,
               let accessDate = resources.contentAccessDate {
                totalSize += size
                cacheFiles.append((url: url, size: size, accessDate: accessDate))
            }
        }
        
        guard totalSize > diskByteLimit else { return }
        
        cacheFiles.sort { $0.accessDate < $1.accessDate }
        var didRemoveKey = false
        
        for file in cacheFiles {
            try? fileManager.removeItem(at: file.url)
            if let key = fileNameToKey.removeValue(forKey: file.url.lastPathComponent) {
                trackedKeys.remove(key)
                didRemoveKey = true
            }
            totalSize -= file.size
            if totalSize <= diskByteLimit { break }
        }
        
        if didRemoveKey {
            persistIndexIfNeeded()
        }
    }
    
    public func invalidate(containing substring: String) {
        let matchingKeys = trackedKeys.filter { $0.localizedStandardContains(substring) }
        expireKeys(matchingKeys)
    }

    public func invalidate(withPrefix prefix: String) {
        let matchingKeys = trackedKeys.filter { $0.hasPrefix(prefix) }
        expireKeys(matchingKeys)
    }
    
    public func delete(containing substring: String) {
        let matchingKeys = trackedKeys.filter { $0.localizedStandardContains(substring) }
        removeKeys(matchingKeys)
    }
    
    public func delete(withPrefix prefix: String) {
        let matchingKeys = trackedKeys.filter { $0.hasPrefix(prefix) }
        removeKeys(matchingKeys)
    }

    // MARK: - Helpers

    private func expireKeys(_ keys: Set<String>) {
        guard !keys.isEmpty else { return }
        
        for key in keys {
            if usesMemory, let memoryEntry = memoryCache.object(forKey: key as NSString) {
                memoryEntry.expirationDate = .distantPast
            }
            
            if usesDisk {
                let fileURL = diskCacheURL.appendingPathComponent(safeFileName(for: key))
                if let entryData = try? Data(contentsOf: fileURL),
                   let diskEntry = try? JSONDecoder().decode(DiskEntry.self, from: entryData) {
                    let expiredEntry = DiskEntry(expirationDate: .distantPast, payload: diskEntry.payload)
                    if let updatedData = try? JSONEncoder().encode(expiredEntry) {
                        try? updatedData.write(to: fileURL)
                    }
                }
            }
        }
    }
    
    private func removeKeys(_ keys: Set<String>) {
        guard !keys.isEmpty else { return }
        
        for key in keys {
            let safeName = safeFileName(for: key)
            memoryCache.removeObject(forKey: key as NSString)
            if usesDisk {
                let fileURL = diskCacheURL.appendingPathComponent(safeName)
                try? fileManager.removeItem(at: fileURL)
            }
            fileNameToKey.removeValue(forKey: safeName)
            trackedKeys.remove(key)
        }
        
        persistIndexIfNeeded()
    }
    
    private func persistIndexIfNeeded() {
        guard usesDisk else { return }
        try? JSONEncoder().encode(trackedKeys).write(to: indexURL)
    }
    
    private func safeFileName(for key: String) -> String {
        Self.computeSafeFileName(for: key)
    }
    
    private static func computeSafeFileName(for key: String) -> String {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
