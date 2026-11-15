//
//  AO3SystemStatusModels.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 7.11.2026.
//

import Foundation

import Foundation

public enum AO3OperationalStatus: String, Codable, Sendable {
    case operational
    case degradedPerformance
    case notOperational
    case unknown
    
    public var isOperational: Bool {
        switch self {
        case .operational, .degradedPerformance:
            return true
        case .notOperational, .unknown:
            return false
        }
    }
}

public struct AO3UptimeDay: Identifiable, Codable, Sendable {
    /// 0 is 90 days ago, 89 is Today (matches `day-0` ... `day-89`).
    public let dayIndex: Int
    /// Raw hex color from the SVG `<rect fill="...">` attribute (e.g. `#2fcc66`, `#e74c3c`).
    public let fillHex: String
    /// Mapped operational status for this day based on its fill color.
    public let status: AO3OperationalStatus

    public var id: Int { dayIndex }

    public init(dayIndex: Int, fillHex: String, status: AO3OperationalStatus) {
        self.dayIndex = dayIndex
        self.fillHex = fillHex
        self.status = status
    }
}

public struct AO3SystemStatus: Codable, Sendable {
    /// Current operational status of Archive of Our Own.
    public let status: AO3OperationalStatus
    /// 90-day uptime percentage scraped from the status page legend (e.g. `81.53`).
    public let uptimePercentage: Double?
    /// The 90 daily status rectangles from oldest (`day-0`) to today (`day-89`).
    public let uptimeDays: [AO3UptimeDay]
    /// The most recent incident logged by OTW Status.
    public let latestIncident: AO3Incident?
    /// When this status was last fetched.
    public let timestamp: Date

    /// Returns `false` only when AO3 is confirmed `notOperational`, allowing requests to still attempt execution during `degradedPerformance`.
    public var isOperational: Bool { status.isOperational }

    public init(
        status: AO3OperationalStatus,
        uptimePercentage: Double? = nil,
        uptimeDays: [AO3UptimeDay] = [],
        latestIncident: AO3Incident? = nil,
        timestamp: Date = Date()
    ) {
        self.status = status
        self.uptimePercentage = uptimePercentage
        self.uptimeDays = uptimeDays
        self.latestIncident = latestIncident
        self.timestamp = timestamp
    }
}


public struct AO3Incident: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let content: String
    public let date: Date
    public let link: String?
    
    public init(id: String, title: String, content: String, date: Date, link: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.link = link
    }
}
