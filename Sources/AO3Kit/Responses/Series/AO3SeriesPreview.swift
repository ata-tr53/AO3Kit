//
//  AO3SeriesPreview.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

public struct AO3SeriesPreview: Identifiable, Sendable, Codable, AO3Response {
    public var id: Int
    
    public var name: String
    public var creators: [AO3AuthorLink]
    public var updateDate: Date?
    
    public var description: String?
    
    public var wordCount: Int
    public var ficCount: Int
    public var bookmarks: Int
    
    public var status: AO3FicStatus
    public var contentRating: AO3ContentRating
    public var relationshipCategories: [AO3RelationshipCategory]
    public var archiveWarnings: [AO3ContentWarning]
    
    public var fandoms: [String]
    public var relationships: [String]
    public var characters: [String]
    public var additionalTags: [String]
    
    public static var responseType: ResponseType { return .series }
}

