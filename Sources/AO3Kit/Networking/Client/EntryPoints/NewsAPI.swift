//
//  NewsAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//


public struct AO3NewsAPI: Sendable {
    internal let client: AO3Client
    
    public func post(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AdminPost {
        return try await client.fetchCachedItem(endpoint: .news(id: id), fallbackStrategy: fallbackStrategy) { html in
            try AO3Parser.parseAdminPost(html: html)
        }
    }
    
    // MARK: Pagination
    
    public func page(page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3AdminPost> {
        
        return try await client.fetchPaginated(
            endpoint: .news(id: nil, route: .main),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseAdminPosts
        )
        
    }
    
    public func all(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3AdminPost] {
        
        return try await client.fetchAllItems(
            endpoint: .news(id: nil, route: .main),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseAdminPosts
        )
        
    }
}
