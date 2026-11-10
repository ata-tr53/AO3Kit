//
//  AO3FicPreview.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

public struct AO3FicPreview: Identifiable, Sendable, Codable, AO3FicModel {
    public var id: Int
    
    public var displayName: String
    public var summary: String?
    public var authors: [AO3AuthorLink]
    public var gifted: [AO3AuthorLink]
    
    public var fandoms: [String]
    public var relationships: [String]
    public var characters: [String]
    public var additionalTags: [String]
    public var series: [AO3SeriesLink]
    
    /// Can be either the Release Date or the Update Date
    public var latestUpdateDate: Date?
    
    public var wordCount: Int
    
    public var currentChapterCount: Int
    public var expectedChapterCount: Int? // nil represents the "?"

    public var isRestricted: Bool
    public var language: String
    
    public var status: AO3FicStatus
    public var contentRating: AO3ContentRating
    public var relationshipCategories: [AO3RelationshipCategory]
    public var archiveWarnings: [AO3ContentWarning]
    
    public var commentCount: Int
    public var kudosCount: Int
    public var bookmarkCount: Int
    public var hitCount: Int?
    
    public static var responseType: ResponseType { return .work }
}


public struct AO3HistoryFicPreview: Identifiable, Sendable, Codable, AO3FicModel {
    public var id: Int { self.preview.id }
    public var displayName: String { self.preview.displayName }
    public static var responseType: ResponseType { return AO3FicPreview.responseType }
    
    public var preview: AO3FicPreview
    
    public var lastVisitTime: Date
    public var newUpdateAvailable: Bool
    public var visitCount: Int
    
    public var isMarkedForLater: Bool
    
    public let deleteActionID: Int
}
