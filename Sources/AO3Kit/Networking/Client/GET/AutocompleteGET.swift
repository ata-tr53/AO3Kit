//
//  AutocompleteGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

internal extension AO3Client {
    
    func fetchAutocomplete(
        scope: AO3AutocompleteScope,
        term: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3AutocompleteResult] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        let endpoint = AO3Endpoint.autocomplete(
            type: scope.endpointType,
            queryItems: scope.queryItems(for: trimmed)
        )
        
        return try await fetchCachedItem(
            endpoint: endpoint,
            headers: [
                "Accept": "application/json, text/javascript, */*; q=0.01",
                "X-Requested-With": "XMLHttpRequest"
            ],
            fallbackStrategy: fallbackStrategy
        ) { jsonString in
            guard let data = jsonString.data(using: .utf8) else {
                throw AO3ClientError.invalidData
            }
            return try JSONDecoder().decode([AO3AutocompleteResult].self, from: data)
        }
    }


}
