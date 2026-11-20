//
//  SeriesAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//


internal struct AO3SeriesAPI: Sendable {
    internal let client: AO3Client
    
    public func metadata(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        return try await client.fetchCachedItem(endpoint: .series(id: id, route: .main), fallbackStrategy: fallbackStrategy) { html in
            try AO3Parser.parseSeries(html: html, seriesID: id)
        }
    }
    
    public func metadata<Series: AO3SeriesModel>(for series: Series, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        try await self.metadata(for: series.id, fallbackStrategy: fallbackStrategy)
    }
    
}
