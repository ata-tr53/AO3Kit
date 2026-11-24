//
//  TagsAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public struct AO3TagsAPI: Sendable {
    internal let client: AO3Client

    // MARK: Tag Details

    /// Fetches canonical status, parent tags, synonyms, metatags, subtags, and child categories for a tag (`/tags/:name`).
    public func details(
        for tagName: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3TagDetails {
        try await client.fetchTagDetails(for: tagName, fallbackStrategy: fallbackStrategy)
    }

    /// Fetches tag details for any `AO3TagModel` (e.g., `AO3FavoriteTag`, `AO3TagSearchResult`, `AO3FandomEntry`).
    public func details<Tag: AO3TagModel>(
        for tag: Tag,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3TagDetails {
        try await client.fetchTagDetails(for: tag.tagName, fallbackStrategy: fallbackStrategy)
    }

    // MARK: Atom Feeds

    /// Fetches the Atom feed for a canonical tag by its numeric AO3 tag ID (`/tags/:id/feed.atom`).
    public func feed(
        forTagID tagID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3TagFeed {
        try await client.fetchTagFeed(forTagID: tagID, fallbackStrategy: fallbackStrategy)
    }

    /// Resolves and fetches the Atom feed for a canonical tag by name.
    public func feed(
        for tagName: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3TagFeed {
        try await client.fetchTagFeed(forTagName: tagName, fallbackStrategy: fallbackStrategy)
    }

    /// Resolves and fetches the Atom feed for any `AO3TagModel`.
    public func feed<Tag: AO3TagModel>(
        for tag: Tag,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3TagFeed {
        try await client.fetchTagFeed(forTagName: tag.tagName, fallbackStrategy: fallbackStrategy)
    }
}
