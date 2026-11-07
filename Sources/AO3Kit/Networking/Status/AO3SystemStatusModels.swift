//
//  AO3SystemStatusModels.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 7.11.2026.
//

import Foundation

public struct AO3SystemStatus: Codable, Sendable {
    /// Indicates if the system is currently considered operational.
    public let isOperational: Bool
    /// The most recent incident logged by OTW Status.
    public let latestIncident: AO3Incident?
    /// When this status was last fetched.
    public let timestamp: Date
}

public struct AO3Incident: Codable, Sendable {
    public let title: String
    public let content: String
    public let date: Date
    public let link: String?
}
