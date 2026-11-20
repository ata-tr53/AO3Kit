//
//  BookmarksAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

internal struct AO3BookmarksAPI: Sendable {
    internal let client: AO3Client
    
    /// Fetches a page of full fic bookmarks (`AO3FicBookmark`) from a user, collection, tag, or series.
    public func page(
        from source: AO3BookmarkSource,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicBookmark> {
        try await client.fetchPaginated(
            endpoint: source.endpoint,
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseBookmarks
        )
    }
    
    /// Fetches all full fic bookmarks (`AO3FicBookmark`) from a user, collection, tag, or series.
    public func all(
        from source: AO3BookmarkSource,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicBookmark] {
        try await client.fetchAllItems(
            endpoint: source.endpoint,
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseBookmarks
        )
    }
    
    // MARK: Work Spesific
    
    /// Fetches a page of short bookmark previews (`AO3BookmarkPreview`) for a specific work.
    public func workPreviewsPage(
        forWorkID workID: Int,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3BookmarkPreview> {
        try await client.fetchWorkBookmarksPage(for: workID, page: page, fallbackStrategy: fallbackStrategy)
    }
    
    /// Fetches a page of short bookmark previews (`AO3BookmarkPreview`) for a specific work.
    public func workPreviewsPage<Fic: AO3FicModel>(
        for work: Fic,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3BookmarkPreview> {
        try await client.fetchWorkBookmarksPage(for: work.id, page: page, fallbackStrategy: fallbackStrategy)
    }
    
    /// Fetches all short bookmark previews (`AO3BookmarkPreview`) for a specific work.
    public func allWorkPreviews(
        forWorkID workID: Int,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3BookmarkPreview] {
        try await client.fetchAllWorkBookmarks(
            for: workID,
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }
    
    /// Fetches all short bookmark previews (`AO3BookmarkPreview`) for a specific work.
    public func allWorkPreviews<Fic: AO3FicModel>(
        for work: Fic,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3BookmarkPreview] {
        try await client.fetchAllWorkBookmarks(
            for: work.id,
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }
}
