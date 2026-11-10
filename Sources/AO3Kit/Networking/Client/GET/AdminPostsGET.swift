//
//  AdminPostsAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

internal extension AO3Client {
    
    func fetchAdminPostsPage(page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3AdminPost> {
        
        return try await self.fetchPaginated(
            endpoint: .news(id: nil, route: .main),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseAdminPosts
        )
        
    }
    
    func fetchAllAdminPosts(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3AdminPost] {
        
        return try await self.fetchAllItems(
            endpoint: .news(id: nil, route: .main),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseAdminPosts
        )
        
    }

    func fetchAdminPost(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AdminPost {
        return try await fetchCachedItem(endpoint: .news(id: id), fallbackStrategy: fallbackStrategy) { html in
            try AO3Parser.parseAdminPost(html: html)
        }
    }
    
}
