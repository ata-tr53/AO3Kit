//
//  UsersGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

public extension AO3Client {
    
    //MARK: User Profile API
    
    func fetchUserProfile(for username: String, pseud: String? = nil, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AuthorMetadata {
        return try await fetchCachedItem(
            endpoint: .user(username: username, route: .profile),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseUserProfile(html: html, username: username)
        }
    }
    
    func fetchUserProfile(for link: AO3AuthorLink, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AuthorMetadata {
        return try await self.fetchUserProfile(for: link.id, fallbackStrategy: fallbackStrategy)
    }
    
    //-----------------------------------------------------------------------------------
    
    //MARK: User Works API
    
    func fetchUserWorks(
        of username: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicPreview> {
        
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .works),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
        
    }
    
    func fetchAllUserWorks(
        of username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicPreview] {
        
        return try await self.fetchAllItems(
            endpoint: .user(username: username, route: .works),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
        
    }
    
    //-----------------------------------------------------------------------------------
    
    //MARK: User History API
    
    func fetchUserHistory(
        of username: String,
        showMarkedForLater: Bool = false,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3HistoryFicPreview> {
        
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .history(showToRead: showMarkedForLater)),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseHistoryFicPreviews
        )
        
    }
    
    func fetchAllUserHistory(
        of username: String,
        maxPages: Int? = nil,
        showMarkedForLater: Bool = false,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3HistoryFicPreview] {
        
        return try await self.fetchAllItems(
            endpoint: .user(username: username, route: .history(showToRead: showMarkedForLater)),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseHistoryFicPreviews
        )
        
    }
    
    //-----------------------------------------------------------------------------------
    
    //MARK: User Gifts API
    
    func fetchUserGifts(
        of username: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicPreview> {
        
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .gifts),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
        
    }
    
    func fetchAllUserGifts(
        of username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicPreview] {
        
        return try await self.fetchAllItems(
            endpoint: .user(username: username, route: .gifts),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
        
    }
    
    //-----------------------------------------------------------------------------------
    
    //MARK: User Series API
    
    func fetchUserSeries(
        of username: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3SeriesPreview> {
        
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .series),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseSeriesPreviews
        )
        
    }
    
    func fetchAllUserSeries(
        of username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3SeriesPreview] {
        
        return try await self.fetchAllItems(
            endpoint: .user(username: username, route: .series),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseSeriesPreviews
        )
        
    }
    
    //-----------------------------------------------------------------------------------
    
    // MARK: - Bookmarks API
    
    func fetchBookmarksPage(
        for username: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicBookmark> {
        
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .bookmarks),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseBookmarks
        )
        
    }
    
    func fetchAllBookmarks(
        for username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicBookmark] {
        
        return try await self.fetchAllItems(
            endpoint: .user(username: username, route: .bookmarks),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseBookmarks
        )
        
    }
    
    // MARK: - User Pseuds API
    
    /// Fetches the list of pseudonyms associated with a specific user.
    func fetchUserPseuds(
        for username: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3AuthorPseudLink] {
        return try await fetchCachedItem(
            endpoint: .user(username: username, route: .allPseuds),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseUserPseuds(html: html)
        }
    }

}
