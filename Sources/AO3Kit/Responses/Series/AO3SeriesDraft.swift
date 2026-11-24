//
//  AO3SeriesDraft.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public struct AO3SeriesDraft: Sendable, Codable, Hashable {
    public var title: String
    public var summary: String
    public var notes: String
    public var isComplete: Bool
    /// Pseud display names to credit on the series. Empty keeps or uses the default pseud.
    public var pseudNames: [String]

    public init(
        title: String,
        summary: String = "",
        notes: String = "",
        isComplete: Bool = false,
        pseudNames: [String] = []
    ) {
        self.title = title
        self.summary = summary
        self.notes = notes
        self.isComplete = isComplete
        self.pseudNames = pseudNames
    }
}
