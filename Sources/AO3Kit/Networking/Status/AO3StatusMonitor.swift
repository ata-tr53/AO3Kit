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
    
    private let statusPageURL = URL(string: "https://www.otwstatus.org")!
    private let uptimeShowcaseBaseURL = "https://www.otwstatus.org/uptime_showcase"
    private let defaultAO3ComponentID = "w84xs5kg4lp6"
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
        let (pageSnapshot, incidents) = try await taskTracker.track(key: feedTaskKey) {
            async let snapshotTask = self.fetchAndParseStatusPage()
            async let feedTask = self.fetchAndParseFeed()

            let incidents = try await feedTask
            let snapshot = try? await snapshotTask
            return (snapshot, incidents)
        }

        let status = buildStatus(snapshot: pageSnapshot, incidents: incidents)
        await AO3RateLimiter.shared.updateStatus(status.status)

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
    
    private func fetchAndParseStatusPage() async throws -> OTWStatusPageSnapshot {
        async let mainPageTask = session.data(from: statusPageURL)
        async let showcaseTask = fetchUptimeShowcaseHTML(componentID: defaultAO3ComponentID)

        let (data, response) = try await mainPageTask

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }

        var snapshot = try AO3Parser.parseOTWStatusPage(html: html)

        if snapshot.uptimeDays.isEmpty {
            let showcaseHTML: String?
            if snapshot.componentID == defaultAO3ComponentID {
                showcaseHTML = try? await showcaseTask
            } else {
                showcaseHTML = try? await fetchUptimeShowcaseHTML(componentID: snapshot.componentID)
            }

            if let showcaseHTML,
               let metrics = try? AO3Parser.parseOTWUptimeShowcase(showcaseHTML: showcaseHTML) {
                snapshot.uptimePercentage = metrics.uptimePercentage
                snapshot.uptimeDays = metrics.uptimeDays
            }
        }

        return snapshot
    }
    
    private func fetchUptimeShowcaseHTML(componentID: String) async throws -> String? {
        guard var components = URLComponents(string: uptimeShowcaseBaseURL) else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "components", value: componentID)]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return nil
        }

        let decoded = try JSONDecoder().decode(OTWUptimeShowcaseResponse.self, from: data)
        return decoded.components?[componentID]
    }

    private func buildStatus(
        snapshot: OTWStatusPageSnapshot?,
        incidents: [AO3Incident]
    ) -> AO3SystemStatus {
        let relevantIncident = incidents.first(where: isRelevantToAO3)

        let resolvedStatus: AO3OperationalStatus
        if let snapshotStatus = snapshot?.status, snapshotStatus != .unknown {
            resolvedStatus = snapshotStatus
        } else if let incident = relevantIncident {
            resolvedStatus = inferStatusFromIncident(incident)
        } else {
            resolvedStatus = .unknown
        }

        return AO3SystemStatus(
            status: resolvedStatus,
            uptimePercentage: snapshot?.uptimePercentage,
            uptimeDays: snapshot?.uptimeDays ?? [],
            latestIncident: relevantIncident ?? incidents.first,
            timestamp: Date()
        )
    }

    private func inferStatusFromIncident(_ incident: AO3Incident) -> AO3OperationalStatus {
        guard isActiveOutage(incident) else {
            return .operational
        }
        let combined = (incident.title + " " + incident.content).lowercased()
        if combined.contains("maintenance") {
            return .underMaintenance
        }
        if combined.contains("degraded") || combined.contains("slow") || combined.contains("partial") {
            return .degradedPerformance
        }
        return .notOperational
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
        
        if let firstStrongRange = contentLower.range(of: "<strong>"),
           let closeStrongRange = contentLower.range(of: "</strong>", range: firstStrongRange.upperBound..<contentLower.endIndex) {
            let latestState = contentLower[firstStrongRange.upperBound..<closeStrongRange.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if ["resolved", "completed", "postmortem", "scheduled"].contains(latestState) {
                return false
            }
            
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
