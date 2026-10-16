//
//  MutedBlockedGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 6.10.2026.
//

import Foundation

public extension AO3Client {
    
    // MARK: - Blocked Users
    
    func fetchBlockedUsersPage(for username: String, page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3MutedBlockedLink> {
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .blocked),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseMutedOrBlockedUsers
        )
    }
    
    func fetchAllBlockedUsers(
        for username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3MutedBlockedLink] {
        return try await self.fetchAllItems(
            endpoint: .user(username: username, route: .blocked),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseMutedOrBlockedUsers
        )
    }
    
    // MARK: - Muted Users
    
    func fetchMutedUsersPage(for username: String, page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3MutedBlockedLink> {
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .muted),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseMutedOrBlockedUsers
        )
    }
    
    func fetchAllMutedUsers(
        for username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3MutedBlockedLink] {
        return try await self.fetchAllItems(
            
            endpoint: .user(username: username, route: .muted),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseMutedOrBlockedUsers
        )
    }
}
