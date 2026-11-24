//
//  BookmarksAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public struct AO3BookmarksAPI: Sendable {
    internal let client: AO3Client
    
    /// Fetches a page of full fic bookmarks (`AO3FicBookmark`) from a user, collection, tag, or series.
    public func page(
        from source: AO3BookmarkSource,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicBookmark> {
        try await client.fetchPaginated(
            url: source.url(bypassAdultBlock: client.bypassAdultBlock),
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
            url: source.url(bypassAdultBlock: client.bypassAdultBlock),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseBookmarks
        )
    }
    
    // MARK: Work Specific
    
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

    // MARK: Single Bookmark & CRUD

    /// Fetches a single bookmark by its ID (`GET /bookmarks/:id`).
    public func bookmark(
        id: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3FicBookmark {
        try await client.fetchBookmark(id: id, fallbackStrategy: fallbackStrategy)
    }

    /// Creates (or updates if one already exists for the current user) a bookmark on a work, series, or external work.
    public func create(
        for target: AO3BookmarkTarget,
        draft: AO3BookmarkDraft
    ) async throws {
        try await client.createBookmark(for: target, draft: draft)
    }

    /// Creates (or updates) a bookmark on any `AO3Bookmarkable` model (e.g., `AO3FicMetadata`, `AO3FicPreview`, `AO3Series`).
    public func create<Target: AO3Bookmarkable>(
        for target: Target,
        draft: AO3BookmarkDraft
    ) async throws {
        try await client.createBookmark(for: target.bookmarkTarget, draft: draft)
    }

    /// Updates an existing bookmark by its ID.
    public func update(
        id: Int,
        draft: AO3BookmarkDraft
    ) async throws {
        try await client.updateBookmark(id: id, draft: draft)
    }

    /// Updates an existing bookmark.
    public func update(
        _ bookmark: AO3FicBookmark,
        draft: AO3BookmarkDraft
    ) async throws {
        try await client.updateBookmark(id: bookmark.id, draft: draft)
    }

    /// Deletes an existing bookmark by its ID.
    public func delete(id: Int) async throws {
        try await client.deleteBookmark(id: id)
    }

    /// Deletes an existing bookmark.
    public func delete(_ bookmark: AO3FicBookmark) async throws {
        try await client.deleteBookmark(id: bookmark.id)
    }

    /// Adds an existing bookmark to one or more collections.
    public func addToCollections(bookmarkID: Int, collectionNames: [String]) async throws {
        try await client.addBookmarkToCollections(bookmarkID: bookmarkID, collectionNames: collectionNames)
    }

    /// Adds an existing bookmark to one or more collections.
    public func addToCollections(_ bookmark: AO3FicBookmark, collectionNames: [String]) async throws {
        try await client.addBookmarkToCollections(bookmarkID: bookmark.id, collectionNames: collectionNames)
    }
}
