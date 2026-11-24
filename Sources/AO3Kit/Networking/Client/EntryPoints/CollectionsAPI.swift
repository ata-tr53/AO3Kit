//
//  CollectionsAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public struct AO3CollectionsAPI: Sendable {
    internal let client: AO3Client
    
    public func profile(for id: String, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Collection {
        return try await client.fetchCachedItem(endpoint: .collection(name: id, route: .profile), fallbackStrategy: fallbackStrategy) { html in
            try AO3Parser.parseCollectionProfile(html: html, collectionID: id)
        }
    }
    
    public func profile<Collection: AO3CollectionModel>(for collection: Collection, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Collection {
        try await self.profile(for: collection.id, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Subcollections
    
    public func subcollectionsPage(for collectionID: String, page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3CollectionPreview> {
        return try await client.fetchPaginated(
            endpoint: .collection(name: collectionID, route: .collections),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
    }
    
    public func subcollectionsPage<Collection: AO3CollectionModel>(for collection: Collection, page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3CollectionPreview> {
        try await self.subcollectionsPage(for: collection.id, page: page, fallbackStrategy: fallbackStrategy)
    }
    
    public func allSubcollections(
        for collectionID: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPreview] {
        return try await client.fetchAllItems(
            endpoint: .collection(name: collectionID, route: .collections),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
    }
    
    public func allSubcollections<Collection: AO3CollectionModel>(
        for collection: Collection,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPreview] {
        try await self.allSubcollections(for: collection.id, maxPages: maxPages, fallbackStrategy: fallbackStrategy, progressHandler: progressHandler)
    }

    // MARK: Browse & Open Challenges

    public func browsePage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3CollectionPreview> {
        try await client.fetchPaginated(
            endpoint: .collectionsIndex(.index),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
    }

    public func allBrowse(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPreview] {
        try await client.fetchAllItems(
            endpoint: .collectionsIndex(.index),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
    }

    public func openChallengesPage(
        kind: AO3ChallengeKind = .all,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3CollectionPreview> {
        try await client.fetchPaginated(
            endpoint: kind.endpoint,
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
    }

    public func allOpenChallenges(
        kind: AO3ChallengeKind = .all,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPreview] {
        try await client.fetchAllItems(
            endpoint: kind.endpoint,
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
    }

    // MARK: Collection Fandoms & Tags

    public func fandoms(
        in collectionID: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FandomEntry] {
        try await client.fetchCachedItem(
            endpoint: .collection(name: collectionID, route: .fandoms),
            cacheKey: "collection_fandoms_\(collectionID)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseFandomsDirectory(html: html)
        }
    }

    public func fandoms<Collection: AO3CollectionModel>(
        in collection: Collection,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FandomEntry] {
        try await fandoms(in: collection.id, fallbackStrategy: fallbackStrategy)
    }

    public func tags(
        in collectionID: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FandomEntry] {
        try await client.fetchCachedItem(
            endpoint: .collection(name: collectionID, route: .tags),
            cacheKey: "collection_tags_\(collectionID)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseCollectionTags(html: html)
        }
    }

    public func tags<Collection: AO3CollectionModel>(
        in collection: Collection,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FandomEntry] {
        try await tags(in: collection.id, fallbackStrategy: fallbackStrategy)
    }

    // MARK: People / Participants

    public func peoplePage(
        in collectionID: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3PersonSearchResult> {
        try await client.fetchPaginated(
            endpoint: .collection(name: collectionID, route: .people(.index)),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parsePeopleSearchResults
        )
    }

    public func peoplePage<Collection: AO3CollectionModel>(
        in collection: Collection,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3PersonSearchResult> {
        try await peoplePage(in: collection.id, page: page, fallbackStrategy: fallbackStrategy)
    }

    public func allPeople(
        in collectionID: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3PersonSearchResult] {
        try await client.fetchAllItems(
            endpoint: .collection(name: collectionID, route: .people(.index)),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parsePeopleSearchResults
        )
    }

    public func allPeople<Collection: AO3CollectionModel>(
        in collection: Collection,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3PersonSearchResult] {
        try await allPeople(
            in: collection.id,
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }

    // MARK: Prompts / Requests

    public func requestsPage(
        in collectionID: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3CollectionPrompt> {
        try await client.fetchPaginated(
            endpoint: .collection(name: collectionID, route: .requests(.index)),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPrompts
        )
    }

    public func requestsPage<Collection: AO3CollectionModel>(
        in collection: Collection,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3CollectionPrompt> {
        try await requestsPage(in: collection.id, page: page, fallbackStrategy: fallbackStrategy)
    }

    public func allRequests(
        in collectionID: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPrompt] {
        try await client.fetchAllItems(
            endpoint: .collection(name: collectionID, route: .requests(.index)),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPrompts
        )
    }

    public func allRequests<Collection: AO3CollectionModel>(
        in collection: Collection,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPrompt] {
        try await allRequests(
            in: collection.id,
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }

    // MARK: Join & Leave

    public func join(collectionID: String) async throws {
        try await client.joinCollection(id: collectionID)
    }

    public func join<Collection: AO3CollectionModel>(_ collection: Collection) async throws {
        try await client.joinCollection(id: collection.id)
    }

    public func leave(collectionID: String) async throws {
        try await client.leaveCollection(id: collectionID)
    }

    public func leave<Collection: AO3CollectionModel>(_ collection: Collection) async throws {
        try await client.leaveCollection(id: collection.id)
    }
}
