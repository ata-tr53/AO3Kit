//
//  SearchAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

internal struct AO3SearchAPI: Sendable {
    internal let client: AO3Client
    
    // MARK: - Autocomplete
    
    public func autocomplete(
        scope: AO3AutocompleteScope,
        for term: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3AutocompleteResult] {
        try await client.fetchAutocomplete(scope: scope, term: term, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: - Works Search
    
    public func worksPage(
        filter: AO3WorkSearchFilter,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicPreview> {
        try await client.fetchPaginated(
            endpoint: .worksSearch(queryItems: filter.queryItems),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
    }
    
    public func allWorks(
        filter: AO3WorkSearchFilter,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicPreview] {
        try await client.fetchAllItems(
            endpoint: .worksSearch(queryItems: filter.queryItems),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
    }
    
    // MARK: - Bookmarks Search
    
    public func bookmarksPage(
        filter: AO3BookmarkSearchFilter,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicBookmark> {
        try await client.fetchPaginated(
            endpoint: .bookmarksSearch(queryItems: filter.queryItems),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseBookmarks
        )
    }
    
    public func allBookmarks(
        filter: AO3BookmarkSearchFilter,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicBookmark] {
        try await client.fetchAllItems(
            endpoint: .bookmarksSearch(queryItems: filter.queryItems),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseBookmarks
        )
    }
    
    // MARK: - Tags Search
    
    public func tagsPage(
        filter: AO3TagSearchFilter,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3TagSearchResult> {
        try await client.fetchPaginated(
            endpoint: .tagsSearch(queryItems: filter.queryItems),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseTagSearchResults
        )
    }
    
    public func allTags(
        filter: AO3TagSearchFilter,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3TagSearchResult] {
        try await client.fetchAllItems(
            endpoint: .tagsSearch(queryItems: filter.queryItems),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseTagSearchResults
        )
    }
    
    // MARK: - People Search
    
    public func peoplePage(
        filter: AO3PeopleSearchFilter,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3PersonSearchResult> {
        try await client.fetchPaginated(
            endpoint: .peopleSearch(queryItems: filter.queryItems),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parsePeopleSearchResults
        )
    }
    
    public func allPeople(
        filter: AO3PeopleSearchFilter,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3PersonSearchResult] {
        try await client.fetchAllItems(
            endpoint: .peopleSearch(queryItems: filter.queryItems),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parsePeopleSearchResults
        )
    }
    
}
