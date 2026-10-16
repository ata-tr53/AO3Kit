//
//  AO3Series.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

public struct AO3Series: Identifiable, Sendable, Codable, AO3Subscribable {
    public var id: Int
    
    public var name: String
    public var creators: [AO3AuthorLink]
    public var startDate: Date
    public var updateDate: Date?
    
    public var description: String?
    public var notes: String?
    
    public var wordCount: Int
    public var ficCount: Int
    public var bookmarks: Int
    
    public var status: AO3FicStatus
    
    public var fics: [AO3FicPreview]
    
    // MARK: Subscribable
    
    public var subscriptionRecordID: Int?
    public var subscribableID: Int { return self.id }
    
    
    public static var responseType: ResponseType { return .series }
    
    public var contentRating: AO3ContentRating { self.fics.map(\.contentRating).max() ?? .notGiven }
    public var relationshipCategories: [AO3RelationshipCategory] { Array(Set(self.fics.flatMap(\.relationshipCategories))) }
    public var archiveWarnings: [AO3ContentWarning] { Array(Set(self.fics.flatMap(\.archiveWarnings))) }
    
    public var fandoms: [String] { Array(Set(self.fics.flatMap(\.fandoms))).sorted() }
    public var relationships: [String] { Array(Set(self.fics.flatMap(\.relationships))).sorted() }
    public var characters: [String] { Array(Set(self.fics.flatMap(\.characters))).sorted() }
    public var additionalTags: [String] { Array(Set(self.fics.flatMap(\.additionalTags))).sorted() }
}
