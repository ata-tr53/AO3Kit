//
//  CollectionsAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//


public struct CollectionsAPI: Sendable {
    internal let client: AO3Client
    
    public func profile(for id: String, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Collection {
        try await client.fetchCollectionProfile(for: id, fallbackStrategy: fallbackStrategy)
    }
    
    public func profile<Collection: AO3CollectionModel>(for collection: Collection, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Collection {
        try await client.fetchCollectionProfile(for: collection.id, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Subcollections
    
    public func subcollectionsPage(for collectionID: String, page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3CollectionPreview> {
        try await client.fetchSubcollectionsPage(for: collectionID, page: page, fallbackStrategy: fallbackStrategy)
    }
    
    public func subcollectionsPage<Collection: AO3CollectionModel>(for collection: Collection, page: Int = 1, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3PaginatedResult<AO3CollectionPreview> {
        try await client.fetchSubcollectionsPage(for: collection.id, page: page, fallbackStrategy: fallbackStrategy)
    }
    
    public func allSubcollections(
        for collectionID: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPreview] {
        try await client.fetchAllSubcollections(for: collectionID, maxPages: maxPages, fallbackStrategy: fallbackStrategy, progressHandler: progressHandler)
    }
    
    public func allSubcollections<Collection: AO3CollectionModel>(
        for collection: Collection,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPreview] {
        try await client.fetchAllSubcollections(for: collection.id, maxPages: maxPages, fallbackStrategy: fallbackStrategy, progressHandler: progressHandler)
    }
}
