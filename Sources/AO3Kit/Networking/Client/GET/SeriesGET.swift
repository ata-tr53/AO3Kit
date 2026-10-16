//
//  SeriesGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

public extension AO3Client {
    
    func fetchSeries(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        return try await fetchCachedItem(endpoint: .series(id: id, route: .main), fallbackStrategy: fallbackStrategy) { html in
            try AO3Parser.parseSeries(html: html, seriesID: id)
        }
    }
    
    func fetchSeries(for link: AO3SeriesLink, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        return try await fetchSeries(for: link.id, fallbackStrategy: fallbackStrategy)
    }
    
    func fetchSeries(for link: AO3SeriesPreview, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        return try await fetchSeries(for: link.id, fallbackStrategy: fallbackStrategy)
    }
}
