//
//  UsersAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public struct AO3UsersAPI: Sendable {
    internal let client: AO3Client
    
    public func profile(for username: String, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AuthorMetadata {
        try await client.fetchUserProfile(for: username, fallbackStrategy: fallbackStrategy)
    }
    
    public func profile<Author: AO3AuthorModel>(for author: Author, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AuthorMetadata {
        try await client.fetchUserProfile(for: author.username, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Pseuds
    
    public func pseuds(for username: String, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> [AO3AuthorPseudLink] {
        try await client.fetchUserPseuds(for: username, fallbackStrategy: fallbackStrategy)
    }
    
    public func pseuds<Author: AO3AuthorModel>(for author: Author, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> [AO3AuthorPseudLink] {
        try await client.fetchUserPseuds(for: author.username, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Series
    
    public func seriesPage(for username: String, page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3SeriesPreview> {
        try await client.fetchUserSeriesPage(for: username, page: page, fallbackStrategy: fallbackStrategy)
    }
    
    public func seriesPage<Author: AO3AuthorModel>(for author: Author, page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3SeriesPreview> {
        try await client.fetchUserSeriesPage(for: author.username, page: page, fallbackStrategy: fallbackStrategy)
    }
    
    public func allSeries(
        for username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3SeriesPreview] {
        try await client.fetchAllUserSeries(for: username, maxPages: maxPages, fallbackStrategy: fallbackStrategy, progressHandler: progressHandler)
    }
    
    public func allSeries<Author: AO3AuthorModel>(
        for author: Author,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3SeriesPreview] {
        try await client.fetchAllUserSeries(for: author.username, maxPages: maxPages, fallbackStrategy: fallbackStrategy, progressHandler: progressHandler)
    }
}
