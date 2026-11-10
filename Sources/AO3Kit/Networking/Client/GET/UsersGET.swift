//
//  UsersGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

internal extension AO3Client {
    
    // MARK: - User Profile API
    
    func fetchUserProfile(
        for username: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3AuthorMetadata {
        return try await fetchCachedItem(
            endpoint: .user(username: username, route: .profile),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseUserProfile(html: html, username: username)
        }
    }
    
    func fetchUserProfile(
        for link: AO3AuthorLink,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3AuthorMetadata {
        return try await self.fetchUserProfile(for: link.id, fallbackStrategy: fallbackStrategy)
    }
    
    //-----------------------------------------------------------------------------------
    
    // MARK: - User History API
    
    func fetchUserHistoryPage(
        for username: String,
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
        for username: String,
        showMarkedForLater: Bool = false,
        maxPages: Int? = nil,
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
    
    // MARK: - User Series API
    
    func fetchUserSeriesPage(
        for username: String,
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
        for username: String,
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
    
    // MARK: - User Pseuds API
    
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
