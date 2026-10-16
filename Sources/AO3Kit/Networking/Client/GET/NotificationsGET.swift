//
//  NotificationsGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 3.10.2026.
//

import Foundation

public extension AO3Client {
    func fetchUserInbox(
        of username: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3Notification> {
        
        return try await self.fetchPaginated(
            endpoint: .user(username: username, route: .inbox),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseInbox
        )
        
    }
    
    func fetchAllUserInbox(
        of username: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3Notification] {
        
        return try await self.fetchAllItems(
            endpoint: .user(username: username, route: .inbox),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseInbox
        )
        
    }
}
