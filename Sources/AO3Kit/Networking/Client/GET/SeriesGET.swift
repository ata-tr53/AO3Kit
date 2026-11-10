//
//  SeriesGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

internal extension AO3Client {
    
    func fetchSeries(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Series {
        return try await fetchCachedItem(endpoint: .series(id: id, route: .main), fallbackStrategy: fallbackStrategy) { html in
            try AO3Parser.parseSeries(html: html, seriesID: id)
        }
    }
    
}
