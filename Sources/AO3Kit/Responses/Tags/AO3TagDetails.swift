//
//  AO3TagDetails.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public struct AO3TagDetails: Identifiable, Sendable, Codable, AO3TagModel {
    public var id: String { name }
    public var tagName: String { name }
    public var name: String
    public var category: String?
    public var isCanonical: Bool
    public var canonicalMerger: String?

    public var parentTags: [String]
    public var synonyms: [String]
    public var metaTags: [String]
    public var subTags: [String]
    public var childCategories: [String: [String]]

    public var worksURL: URL? {
        AO3Endpoint.tag(name: name, route: .works).url()
    }

    public var bookmarksURL: URL? {
        AO3Endpoint.tag(name: name, route: .bookmarks).url()
    }

    public init(
        name: String,
        category: String? = nil,
        isCanonical: Bool = false,
        canonicalMerger: String? = nil,
        parentTags: [String] = [],
        synonyms: [String] = [],
        metaTags: [String] = [],
        subTags: [String] = [],
        childCategories: [String: [String]] = [:]
    ) {
        self.name = name
        self.category = category
        self.isCanonical = isCanonical
        self.canonicalMerger = canonicalMerger
        self.parentTags = parentTags
        self.synonyms = synonyms
        self.metaTags = metaTags
        self.subTags = subTags
        self.childCategories = childCategories
    }
}
