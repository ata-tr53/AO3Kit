//
//  StatisticsGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 4.10.2026.
//

import Foundation

internal extension AO3Client {
    
    func fetchUserStatistics(
        for username: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3UserStatistics {
        
        return try await fetchCachedItem(
            endpoint: .user(username: username, route: .stats),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseUserStatistics(html: html, username: username)
        }
        
    }
    
}
