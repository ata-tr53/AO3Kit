//
//  TagsGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

internal extension AO3Client {

    func fetchTagDetails(
        for tagName: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3TagDetails {
        try await fetchCachedItem(
            endpoint: .tag(name: tagName, route: .main),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseTagDetails(html: html, tagName: tagName)
        }
    }

    func fetchTagFeed(
        forTagID tagID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3TagFeed {
        try await fetchCachedItem(
            endpoint: .tag(name: String(tagID), route: .feed(atom: true)),
            cacheKey: "tag_feed_\(tagID)",
            headers: ["Accept": "application/atom+xml, application/xml, text/xml"],
            fallbackStrategy: fallbackStrategy
        ) { xmlString in
            guard let data = xmlString.data(using: .utf8) else {
                throw AO3ClientError.invalidData
            }
            return try AO3TagFeedParser(data: data).parse()
        }
    }

    func fetchTagFeed(
        forTagName tagName: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3TagFeed {
        guard let worksURL = AO3Endpoint.tag(name: tagName, route: .works).url(bypassAdultBlock: self.bypassAdultBlock) else {
            throw AO3ClientError.invalidURL
        }
        let worksHTML = try await performRequest(url: worksURL)
        guard let feedURL = try AO3Parser.parseTagFeedURL(from: worksHTML) else {
            throw AO3ClientError.invalidEndpoint
        }
        return try await fetchCachedItem(
            url: feedURL,
            cacheKey: "tag_feed_name_\(tagName)",
            headers: ["Accept": "application/atom+xml, application/xml, text/xml"],
            fallbackStrategy: fallbackStrategy
        ) { xmlString in
            guard let data = xmlString.data(using: .utf8) else {
                throw AO3ClientError.invalidData
            }
            return try AO3TagFeedParser(data: data).parse()
        }
    }

    func fetchMediaCategories(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3MediaCategory] {
        try await fetchCachedItem(
            endpoint: .media(.index),
            cacheKey: "media_categories",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseMediaCategories(html: html)
        }
    }

    func fetchFandoms(
        inMedia mediaID: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FandomEntry] {
        try await fetchCachedItem(
            endpoint: .media(.fandoms(mediaID: mediaID, action: .index)),
            cacheKey: "media_fandoms_\(mediaID)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseFandomsDirectory(html: html)
        }
    }

    func fetchUnassignedFandomsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FandomEntry> {
        try await fetchPaginated(
            endpoint: .fandom(.unassigned),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFandomsDirectory
        )
    }

    func fetchAllUnassignedFandoms(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FandomEntry] {
        try await fetchAllItems(
            endpoint: .fandom(.unassigned),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFandomsDirectory
        )
    }

    func fetchLanguages(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Language] {
        try await fetchCachedItem(
            endpoint: .language(.index),
            cacheKey: "ao3_languages",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseLanguages(html: html)
        }
    }
}
