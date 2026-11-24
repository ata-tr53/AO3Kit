//
//  AO3TagFeed.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 24.11.2026.
//

import Foundation

public struct AO3TagFeed: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public var id: String
    public var title: String
    public var updated: Date?
    public var feedURL: URL?
    public var entries: [AO3TagFeedEntry]

    public static var responseType: ResponseType { .tagFeed }

    public init(
        id: String,
        title: String,
        updated: Date? = nil,
        feedURL: URL? = nil,
        entries: [AO3TagFeedEntry] = []
    ) {
        self.id = id
        self.title = title
        self.updated = updated
        self.feedURL = feedURL
        self.entries = entries
    }
}

public struct AO3TagFeedEntry: Identifiable, Sendable, Codable, Hashable {
    /// Raw Atom `<id>` (e.g., `"tag:archiveofourown.org,2005:Work/12345678"`).
    public let id: String
    /// Numeric AO3 work ID extracted from `<link>` or `<id>`.
    public let workID: Int?
    public let title: String
    public let authors: [String]
    public let published: Date?
    public let updated: Date?
    public let url: URL?
    /// Raw HTML inside `<summary type="html">` containing work summary and tag/stat metadata.
    public let summaryHTML: String

    public init(
        id: String,
        workID: Int? = nil,
        title: String,
        authors: [String] = [],
        published: Date? = nil,
        updated: Date? = nil,
        url: URL? = nil,
        summaryHTML: String = ""
    ) {
        self.id = id
        self.workID = workID
        self.title = title
        self.authors = authors
        self.published = published
        self.updated = updated
        self.url = url
        self.summaryHTML = summaryHTML
    }
}
