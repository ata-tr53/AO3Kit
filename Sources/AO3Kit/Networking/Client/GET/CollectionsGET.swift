//
//  CollectionsGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

internal extension AO3Client {
    
    //MARK: Collection Profile API
    
    func fetchCollectionProfile(for id: String, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Collection {
        
        return try await fetchCachedItem(endpoint: .collection(name: id, route: .profile), fallbackStrategy: fallbackStrategy) { html in
            try AO3Parser.parseCollectionProfile(html: html, collectionID: id)
        }
        
    }
    
    //MARK: Collection Subcollections API
    
    func fetchSubcollectionsPage(
        for collectionID: String,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3CollectionPreview> {
        
        return try await self.fetchPaginated(
            endpoint: .collection(name: collectionID, route: .collections),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
        
    }
    
    func fetchAllSubcollections(
        for collectionID: String,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPreview] {
        
        return try await self.fetchAllItems(
            endpoint: .collection(name: collectionID, route: .collections),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
        
    }
}
