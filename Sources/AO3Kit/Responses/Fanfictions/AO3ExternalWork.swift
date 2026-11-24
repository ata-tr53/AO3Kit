//
//  AO3ExternalWork.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public struct AO3ExternalWork: Identifiable, Sendable, Codable, Hashable, AO3Response, AO3Bookmarkable {
    public let id: Int
    public let title: String
    public let author: String
    public let externalURL: URL?
    public let summary: String?
    public let fandoms: [String]
    public let relationships: [String]
    public let characters: [String]
    public let additionalTags: [String]
    public let rating: AO3ContentRating
    public let categories: [AO3RelationshipCategory]
    public let bookmarkCount: Int

    public static var responseType: ResponseType { .externalWork }
    public var bookmarkableID: Int { id }
    public var bookmarkTarget: AO3BookmarkTarget { .externalWork(id: id) }

    public var url: URL? {
        AO3Endpoint.externalWork(.show(id: id)).url()
    }

    public init(
        id: Int,
        title: String,
        author: String,
        externalURL: URL? = nil,
        summary: String? = nil,
        fandoms: [String] = [],
        relationships: [String] = [],
        characters: [String] = [],
        additionalTags: [String] = [],
        rating: AO3ContentRating = .notGiven,
        categories: [AO3RelationshipCategory] = [],
        bookmarkCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.externalURL = externalURL
        self.summary = summary
        self.fandoms = fandoms
        self.relationships = relationships
        self.characters = characters
        self.additionalTags = additionalTags
        self.rating = rating
        self.categories = categories
        self.bookmarkCount = bookmarkCount
    }
}

public struct AO3ExternalWorkDraft: Sendable, Codable, Hashable {
    public var url: URL
    public var title: String
    public var author: String
    public var summary: String
    public var fandoms: [String]
    public var rating: AO3ContentRating
    public var categories: [AO3RelationshipCategory]
    public var relationships: [String]
    public var characters: [String]
    public var additionalTags: [String]

    public init(
        url: URL,
        title: String,
        author: String,
        fandoms: [String],
        summary: String = "",
        rating: AO3ContentRating = .notGiven,
        categories: [AO3RelationshipCategory] = [],
        relationships: [String] = [],
        characters: [String] = [],
        additionalTags: [String] = []
    ) {
        self.url = url
        self.title = title
        self.author = author
        self.fandoms = fandoms
        self.summary = summary
        self.rating = rating
        self.categories = categories
        self.relationships = relationships
        self.characters = characters
        self.additionalTags = additionalTags
    }
}
