//
//  DownloadsGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

internal extension AO3Client {

    func fetchDownloadLinks(
        for workID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3DownloadLink] {
        let endpoint: AO3Endpoint = .work(id: workID, route: .main)
        guard let url = endpoint.url(bypassAdultBlock: self.bypassAdultBlock) else {
            throw AO3ClientError.invalidURL
        }

        return try await fetchCachedItem(
            url: url,
            cacheKey: "download_links_\(workID)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseDownloadLinks(html: html, workID: workID)
        }
    }

    func downloadWork(from link: AO3DownloadLink) async throws -> AO3WorkDownload {
        let taskKey = "work_download_\(link.workID)_\(link.format.rawValue)"

        let data: Data = try await taskTracker.track(key: taskKey) {
            try await AO3NetworkMonitor.shared.requireConnection()
            try await AO3RateLimiter.shared.waitIfNeeded()

            var request = URLRequest(url: link.url)
            request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

            let (data, response) = try await self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AO3ClientError.invalidResponse
            }

            return data
        }

        let safeTitle = link.title.replacingOccurrences(of: "/", with: "-")
        let filename = "\(safeTitle).\(link.format.fileExtension)"

        return AO3WorkDownload(
            workID: link.workID,
            format: link.format,
            suggestedFilename: filename,
            data: data
        )
    }

    func downloadWork(
        workID: Int,
        format: AO3DownloadFormat,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3WorkDownload {
        let links = try await fetchDownloadLinks(for: workID, fallbackStrategy: fallbackStrategy)
        guard let match = links.first(where: { $0.format == format }) else {
            throw AO3ClientError.noDataFound
        }
        return try await downloadWork(from: match)
    }
}
