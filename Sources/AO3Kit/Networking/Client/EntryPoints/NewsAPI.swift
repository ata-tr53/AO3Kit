//
//  NewsAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//


public struct NewsAPI: Sendable {
    internal let client: AO3Client
    
    public func post(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AdminPost {
        try await client.fetchAdminPost(for: id, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Pagination
    
    public func page(page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3AdminPost> {
        try await client.fetchAdminPostsPage(page: page, fallbackStrategy: fallbackStrategy)
    }
    
    public func all(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3AdminPost] {
        try await client.fetchAllAdminPosts(maxPages: maxPages, fallbackStrategy: fallbackStrategy, progressHandler: progressHandler)
    }
}
