//
//  SeriesAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//


public struct SeriesAPI: Sendable {
    internal let client: AO3Client
    
    public func metadata(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        try await client.fetchSeries(for: id, fallbackStrategy: fallbackStrategy)
    }
    
    public func metadata<Series: AO3SeriesModel>(for series: Series, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        try await client.fetchSeries(for: series.id, fallbackStrategy: fallbackStrategy)
    }
    
}
