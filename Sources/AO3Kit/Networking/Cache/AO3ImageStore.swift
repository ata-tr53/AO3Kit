//
//  AO3ImageStore.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 11.11.2026.
//

import Foundation
import CryptoKit

public actor AO3ImageStore {
    
    private final class MemoryEntry: NSObject {
        let data: Data
        init(data: Data) { self.data = data }
    }
    
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    private let memoryCache = NSCache<NSString, MemoryEntry>()
    
    public let storageStrategy: AO3CacheStrategy
    public let diskByteLimit: Int
    
    private var usesMemory: Bool { storageStrategy == .memoryOnly || storageStrategy == .both }
    private var usesDisk: Bool { storageStrategy == .diskOnly || storageStrategy == .both }
    
    public init(
        diskDirectoryName: String = "AO3KitImageCache",
        storageStrategy: AO3CacheStrategy = .both,
        memoryCountLimit: Int = 50,
        diskByteLimit: Int = 100 * 1024 * 1024 // 100 MB default for images
    ) {
        self.storageStrategy = storageStrategy
        self.diskByteLimit = diskByteLimit
        self.memoryCache.countLimit = memoryCountLimit
        
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = urls[0].appendingPathComponent(diskDirectoryName)
        self.diskCacheURL = cacheDir
        
        if storageStrategy != .memoryOnly {
            if !fileManager.fileExists(atPath: cacheDir.path) {
                try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }
        }
    }
    
    // MARK: - Read
    
    public func data(forKey key: String) -> Data? {
        let nsKey = key as NSString
        
        // 1. Check RAM
        if usesMemory, let memEntry = memoryCache.object(forKey: nsKey) {
            return memEntry.data
        }
        
        // 2. Check Disk
        if usesDisk {
            var fileURL = diskCacheURL.appendingPathComponent(safeFileName(for: key))
            if let diskData = try? Data(contentsOf: fileURL) {
                // Populate RAM for subsequent reads
                if usesMemory {
                    memoryCache.setObject(MemoryEntry(data: diskData), forKey: nsKey)
                }
                
                // Update access timestamp for LRU tracking
                var resourceValues = URLResourceValues()
                resourceValues.contentAccessDate = Date()
                try? fileURL.setResourceValues(resourceValues)
                
                return diskData
            }
        }
        
        return nil
    }
    
    // MARK: - Write
    
    public func store(_ data: Data, forKey key: String) {
        let nsKey = key as NSString
        
        if usesMemory {
            memoryCache.setObject(MemoryEntry(data: data), forKey: nsKey)
        }
        
        if usesDisk {
            let fileURL = diskCacheURL.appendingPathComponent(safeFileName(for: key))
            try? data.write(to: fileURL)
            enforceDiskLimit()
        }
    }
    
    // MARK: - Deletion & Eviction
    
    public func delete(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        if usesDisk {
            let fileURL = diskCacheURL.appendingPathComponent(safeFileName(for: key))
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    public func clearAll() {
        memoryCache.removeAllObjects()
        if usesDisk {
            try? fileManager.removeItem(at: diskCacheURL)
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
    /// Trims the disk cache down to `diskByteLimit` by evicting the Least Recently Used (LRU) image files.
    private func enforceDiskLimit() {
        guard usesDisk, diskByteLimit > 0 else { return }
        
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
}
