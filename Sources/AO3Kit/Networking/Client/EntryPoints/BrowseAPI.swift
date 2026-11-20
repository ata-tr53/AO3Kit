//
//  BrowseAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

public struct AO3BrowseAPI: Sendable {
    internal let client: AO3Client

    // MARK: Media & Fandoms

    /// Fetches all top-level AO3 media categories and their featured fandoms (`/media`).
    public func mediaCategories(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3MediaCategory] {
        try await client.fetchMediaCategories(fallbackStrategy: fallbackStrategy)
    }

    /// Fetches all fandoms listed under a given media category (`/media/:id/fandoms`).
    public func fandoms(
        inMedia mediaID: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FandomEntry] {
        try await client.fetchFandoms(inMedia: mediaID, fallbackStrategy: fallbackStrategy)
    }

    /// Fetches all fandoms listed under a given `AO3MediaCategory`.
    public func fandoms(
        in media: AO3MediaCategory,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FandomEntry] {
        try await client.fetchFandoms(inMedia: media.id, fallbackStrategy: fallbackStrategy)
    }

    /// Fetches a page of unassigned fandoms (`/fandoms/unassigned`).
    public func unassignedFandomsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FandomEntry> {
        try await client.fetchUnassignedFandomsPage(page: page, fallbackStrategy: fallbackStrategy)
    }

    /// Fetches all unassigned fandoms across pages (`/fandoms/unassigned`).
    public func allUnassignedFandoms(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FandomEntry] {
        try await client.fetchAllUnassignedFandoms(
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }

    // MARK: Languages

    /// Fetches all supported AO3 languages and their work counts (`/languages`).
    public func languages(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Language] {
        try await client.fetchLanguages(fallbackStrategy: fallbackStrategy)
    }
}
