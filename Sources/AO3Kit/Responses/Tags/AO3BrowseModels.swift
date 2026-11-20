//
//  AO3BrowseModels.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public struct AO3FandomEntry: Identifiable, Sendable, Codable, AO3TagModel {
    public var id: String { name }
    public var tagName: String { name }
    public var name: String
    public var workCount: Int

    public init(name: String, workCount: Int) {
        self.name = name
        self.workCount = workCount
    }
}

public struct AO3MediaCategory: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public var id: String
    public var name: String
    public var featuredFandoms: [AO3FandomEntry]

    public var allFandomsURL: URL? {
        AO3Endpoint.media(.fandoms(mediaID: id, action: .index)).url()
    }

    public static var responseType: ResponseType { .media }

    public init(id: String, name: String, featuredFandoms: [AO3FandomEntry] = []) {
        self.id = id
        self.name = name
        self.featuredFandoms = featuredFandoms
    }
}
