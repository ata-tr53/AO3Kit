//
//  AuthGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation
import SwiftSoup

internal extension AO3Client {
    
    // MARK: - Session Management
    
    /// Synchronously checks local cookie storage to determine if an active session exists.
    var isLoggedIn: Bool {
        guard let url = URL(string: "https://archiveofourown.org"),
              let cookies = session.configuration.httpCookieStorage?.cookies(for: url) else {
            return false
        }
        
        return cookies.contains { $0.name == "_otwarchive_session" || $0.name == "user_credentials" }
    }
    
    /// Destroys the current user session by deleting AO3 authentication cookies.
    func logout() {
        cachedCSRFToken = nil
        cachedUsername = nil
        Task {
            await cache.invalidate(containing: "Homepage")
        }
        
        guard let url = URL(string: "https://archiveofourown.org"),
              let cookieStorage = session.configuration.httpCookieStorage,
              let cookies = cookieStorage.cookies(for: url) else {
            return
        }
        
        for cookie in cookies where cookie.name == "_otwarchive_session" || cookie.name == "user_credentials" {
            cookieStorage.deleteCookie(cookie)
        }
    }
    
    
    // MARK: - Current User API
    
    /// Fetches the currently authenticated user's basic info, including their profile picture.
    func fetchCurrentUser(fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AuthorLink {
        return try await fetchCachedItem(
            endpoint: .home,
            cacheKey: "Homepage",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseCurrentUser(from: html)
        }
    }
    
    /// Fetches the full profile metadata for the currently authenticated user.
    func fetchCurrentUserProfile(fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AuthorMetadata {
        let currentUser = try await fetchCurrentUser(fallbackStrategy: fallbackStrategy)
        return try await fetchUserProfile(for: currentUser, fallbackStrategy: fallbackStrategy)
    }

    // MARK: - Subscriptions API
    
    func fetchSubscriptionsPage(
        for username: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3Subscription> {
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .subscriptions),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseSubscriptions
        )
    }
    
    func fetchAllSubscriptions(
        for username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3Subscription] {
        
        return try await self.fetchAllItems(
            endpoint: .user(username: username, route: .subscriptions),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseSubscriptions
        )
    }

}
