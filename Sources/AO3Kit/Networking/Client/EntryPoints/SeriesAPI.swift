//
//  SeriesAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//


public struct AO3SeriesAPI: Sendable {
    internal let client: AO3Client
    
    public func metadata(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        return try await client.fetchCachedItem(endpoint: .series(id: id, route: .main), fallbackStrategy: fallbackStrategy) { html in
            try AO3Parser.parseSeries(html: html, seriesID: id)
        }
    }
    
    public func metadata<Series: AO3SeriesModel>(for series: Series, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        try await self.metadata(for: series.id, fallbackStrategy: fallbackStrategy)
    }

    // MARK: Series CRUD & Reordering

    public func update(id seriesID: Int, draft: AO3SeriesDraft) async throws {
        try await client.updateSeries(id: seriesID, draft: draft)
    }

    public func update<Series: AO3SeriesModel>(_ series: Series, draft: AO3SeriesDraft) async throws {
        try await client.updateSeries(id: series.id, draft: draft)
    }

    public func delete(id seriesID: Int) async throws {
        try await client.deleteSeries(id: seriesID)
    }

    public func delete<Series: AO3SeriesModel>(_ series: Series) async throws {
        try await client.deleteSeries(id: series.id)
    }

    public func reorderWorks(seriesID: Int, serialWorkIDsInOrder: [Int]) async throws {
        try await client.reorderSeriesWorks(seriesID: seriesID, serialWorkIDsInOrder: serialWorkIDsInOrder)
    }

    public func reorderWorks<Series: AO3SeriesModel>(for series: Series, serialWorkIDsInOrder: [Int]) async throws {
        try await client.reorderSeriesWorks(seriesID: series.id, serialWorkIDsInOrder: serialWorkIDsInOrder)
    }

    public func removeCreatorship(seriesID: Int) async throws {
        try await client.removeSeriesCreatorship(seriesID: seriesID)
    }

    public func removeCreatorship<Series: AO3SeriesModel>(for series: Series) async throws {
        try await client.removeSeriesCreatorship(seriesID: series.id)
    }
}
