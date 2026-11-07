//
//  AO3StatusMonitor.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 7.11.2026.
//

import Foundation

public actor AO3StatusMonitor {
    
    public static let shared = AO3StatusMonitor()
    
    private let cache: AO3Cache
    private let cacheKey = "OTW_System_Status"
    
    private let feedURL = URL(string: "https://www.otwstatus.org/history.atom")!
    
    private init() {
        self.cache = AO3Cache(
            diskDirectoryName: "AO3KitStatusCache",
            defaultTTL: 600,
            storageStrategy: .both,
            expirationStrategy: .keepUntilReplaced,
            memoryCountLimit: 2,
            diskByteLimit: 1024 * 1024
        )
    }
    
    public func currentStatus(forceRefresh: Bool = false) async throws -> AO3SystemStatus {
        if !forceRefresh {
            let cacheResponse: AO3CacheResponse<AO3SystemStatus> = try await cache.get(forKey: cacheKey)
            if cacheResponse.state == .upToDate, let cachedStatus = cacheResponse.data {
                return cachedStatus
            }
        }
        
        let status = try await fetchAndParseStatus()
        try await cache.set(status, forKey: cacheKey)
        
        return status
    }
    
    private func fetchAndParseStatus() async throws -> AO3SystemStatus {
        let (data, response) = try await URLSession.shared.data(from: feedURL)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let parser = AtomFeedParser(data: data)
        let incidents = try parser.parse()
        
        let latest = incidents.first
        
        var isOperational = true
        if let latest = latest {
            let titleLower = latest.title.lowercased()
            let contentLower = latest.content.lowercased()
            
            let indicatesProblem = titleLower.contains("outage") ||
                                   titleLower.contains("down") ||
                                   titleLower.contains("issues") ||
                                   titleLower.contains("maintenance")
            
            let indicatesResolved = titleLower.contains("resolved") ||
                                    titleLower.contains("completed") ||
                                    contentLower.contains("functions are now processing normally")
            
            if indicatesProblem && !indicatesResolved {
                isOperational = false
            }
        }
        
        return AO3SystemStatus(
            isOperational: isOperational,
            latestIncident: latest,
            timestamp: Date()
        )
    }
}
