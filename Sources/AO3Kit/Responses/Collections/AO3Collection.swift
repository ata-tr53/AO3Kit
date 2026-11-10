//
//  AO3Collection.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//


import Foundation

public struct AO3Collection: Identifiable, Sendable, Codable, AO3CollectionModel {
    /// The unique, URL-safe short name
    public var id: String 
    
    /// The formatted display name.
    public var displayName: String
    
    /// The collection's avatar/icon, if it has one.
    public var icon: AO3Image?
    
    /// Users who run and moderate the collection.
    public var maintainers: [AO3AuthorLink]
    
    /// If this collection is a subcollection, this links to the parent.
    public var parentCollection: AO3CollectionLink?
    
    // MARK: - Profile Text Fields
    
    public var summaryHTML: String?
    public var faqHTML: String?
    public var rulesHTML: String?
    
    // MARK: - Configuration Flags
    
    /// Bitmask containing the open/moderated/unrevealed/anonymous states.
    public var options: AO3CollectionOptions
    
    public var isOpen: Bool { options.contains(.open) }
    public var isModerated: Bool { options.contains(.moderated) }
    public var isUnrevealed: Bool { options.contains(.unrevealed) }
    public var isAnonymous: Bool { options.contains(.anonymous) }
    
    // MARK: - Challenge Types
    
    /// AO3 Collections can optionally host challenges which change the available navigation links.
    public var challengeType: AO3ChallengeType?
    
    // MARK: - Dashboard Statistics
    
    public var fandomCount: Int
    public var workCount: Int
    public var bookmarkCount: Int
    public var subCollectionCount: Int
    
    public var date: Date
    
    // MARK: - Computed Properties
    
    public static var responseType: ResponseType { return .collection }
    
    public var url: URL? {
        return URL(string: "https://archiveofourown.org/collections/\(id)")
    }
}


public enum AO3ChallengeType: String, Sendable, Codable, Hashable {
    case giftExchange = "Gift Exchange"
    case promptMeme = "Prompt Meme"
}
