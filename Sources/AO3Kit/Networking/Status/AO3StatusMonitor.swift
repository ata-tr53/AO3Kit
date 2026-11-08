//
//  AO3StatusMonitor.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 7.11.2026.
//

import Foundation

public actor AO3StatusMonitor {
    
    public static let shared = AO3StatusMonitor()
    
    private let cache: AO3Cache
    private let taskTracker = AO3TaskTracker()
    private let session: URLSession
    
    private let statusCacheKey = "OTW_System_Status"
    private let incidentsCacheKey = "OTW_Recent_Incidents"
    private let feedTaskKey = "OTW_Atom_Feed_Fetch"
    
    private let feedURL = URL(string: "https://www.otwstatus.org/history.atom")!
    
    public init(session: URLSession = .shared) {
        self.session = session
        self.cache = AO3Cache(
            diskDirectoryName: "AO3KitStatusCache",
            defaultTTL: 600,
            storageStrategy: .both,
            expirationStrategy: .keepUntilReplaced,
            memoryCountLimit: 4,
            diskByteLimit: 1024 * 1024
        )
    }
    
    // MARK: - Endpoints
    
    public func currentStatus(forceRefresh: Bool = false) async throws -> AO3SystemStatus {
        if !forceRefresh,
           let response: AO3CacheResponse<AO3SystemStatus> = try? await cache.get(forKey: statusCacheKey),
           response.state == .upToDate,
           let cachedStatus = response.data {
            return cachedStatus
        }
        
        let (status, _) = try await refreshFeedAndCache()
        return status
    }
    
    public func recentIncidents(forceRefresh: Bool = false) async throws -> [AO3Incident] {
        if !forceRefresh,
           let response: AO3CacheResponse<[AO3Incident]> = try? await cache.get(forKey: incidentsCacheKey),
           response.state == .upToDate,
           let cachedIncidents = response.data {
            return cachedIncidents
        }
        
        let (_, incidents) = try await refreshFeedAndCache()
        return incidents
    }
    
    // MARK: - Internal Logic
    
    private func refreshFeedAndCache() async throws -> (AO3SystemStatus, [AO3Incident]) {
        let incidents = try await taskTracker.track(key: feedTaskKey) {
            try await self.fetchAndParseFeed()
        }
        let status = buildStatus(from: incidents)
        
        try? await cache.set(status, forKey: statusCacheKey)
        try? await cache.set(incidents, forKey: incidentsCacheKey)
        
        return (status, incidents)
    }
    
    private func fetchAndParseFeed() async throws -> [AO3Incident] {
        let (data, response) = try await session.data(from: feedURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let parser = AtomFeedParser(data: data)
        return try parser.parse()
    }
    
    private func buildStatus(from incidents: [AO3Incident]) -> AO3SystemStatus {
        let relevantIncident = incidents.first(where: isRelevantToAO3)
        let isOperational: Bool
        
        if let incident = relevantIncident {
            isOperational = !isActiveOutage(incident)
        } else {
            isOperational = true
        }
        
        return AO3SystemStatus(
            isOperational: isOperational,
            latestIncident: relevantIncident ?? incidents.first,
            timestamp: Date()
        )
    }
    
    private func isRelevantToAO3(_ incident: AO3Incident) -> Bool {
        let combined = (incident.title + " " + incident.content).lowercased()
        if combined.contains("archive of our own") || combined.contains("ao3") {
            return true
        }
        let otherOTWProperties = ["fanlore", "open doors", "transformative works and cultures", "legal advocacy"]
        if otherOTWProperties.contains(where: { combined.contains($0) }) {
            return false
        }
        return true
    }
    
    private func isActiveOutage(_ incident: AO3Incident) -> Bool {
        let titleLower = incident.title.lowercased()
        let contentLower = incident.content.lowercased()
        
        // In Statuspage Atom feeds, the newest update is the first <strong>State</strong> block
        if let firstStrongRange = contentLower.range(of: "<strong>"),
           let closeStrongRange = contentLower.range(of: "</strong>", range: firstStrongRange.upperBound..<contentLower.endIndex) {
            let latestState = contentLower[firstStrongRange.upperBound..<closeStrongRange.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Resolved, completed, postmortem, or future scheduled notices mean AO3 is currently up
            if ["resolved", "completed", "postmortem", "scheduled"].contains(latestState) {
                return false
            }
            // Active incident states on Statuspage
            if ["investigating", "identified", "in progress", "verifying"].contains(latestState) {
                return true
            }
        }
        
        let indicatesResolved = titleLower.contains("resolved") ||
                                titleLower.contains("completed") ||
                                contentLower.contains("this incident has been resolved") ||
                                contentLower.contains("functions are now processing normally")
        if indicatesResolved {
            return false
        }
        
        let indicatesProblem = titleLower.contains("outage") ||
                               titleLower.contains("down") ||
                               titleLower.contains("issues") ||
                               titleLower.contains("maintenance") ||
                               titleLower.contains("error")
        return indicatesProblem
    }
}
