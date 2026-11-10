//
//  AO3CollectionPreview.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation


public struct AO3CollectionPreview: Identifiable, Sendable, Codable, AO3CollectionModel {
    /// The unique, URL-safe short name
    public var id: String
    
    /// The formatted display name.
    public var displayName: String
    
    /// The collection's avatar/icon, if it has one.
    public var icon: AO3Image?
    
    /// Users who run and moderate the collection.
    public var maintainers: [AO3AuthorLink]
    
    // MARK: - Profile Text Fields
    
    public var summaryHTML: String?
    
    // MARK: - Configuration Flags
    
    /// Bitmask containing the open/moderated/unrevealed/anonymous states.
    public var options: AO3CollectionOptions
    
    public var isOpen: Bool { options.contains(.open) }
    public var isModerated: Bool { options.contains(.moderated) }
    public var isUnrevealed: Bool { options.contains(.unrevealed) }
    public var isAnonymous: Bool { options.contains(.anonymous) }
    
    
    public var workCount: Int
    public var bookmarkCount: Int
    
    public var date: Date
    
    public static var responseType: ResponseType { return .collection }
}
