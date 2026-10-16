//
//  AO3AuthorMetadata.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

public struct AO3AuthorMetadata: Identifiable, Sendable, Codable, Hashable, AO3Subscribable, AO3Mutable, AO3Blockable {
    
    public var id: Int
    
    public var username: String
    public var profilePicture: AO3Image
    
    public var pseuds: [String]
    public var joinDate: Date
    
    public var biography: String?
    
    // MARK: - Dashboard Statistics
    
    public var workCount: Int
    public var seriesCount: Int
    public var bookmarkCount: Int
    public var collectionCount: Int
    public var giftsCount: Int
    
    /// The additional data that is present if the profile is owned by the user
    public var signedInMetadata: AO3SignedInUserMetadata?
    
    // MARK: Subscribable
    
    public var subscriptionRecordID: Int?
    public var subscribableID: Int { return self.id }
    
    // MARK: - Mute & Block Metadata
    
    public var unblockActionID: Int?
    public var unmuteActionID: Int?
    
    public static var responseType: ResponseType { return .user }
    
    
    public var countDictionary: [String: Int] {
        return [
            "Works": self.workCount,
            "Series": self.seriesCount,
            "Bookmarks": self.bookmarkCount,
            "Collection": self.collectionCount,
            "Gifts": self.giftsCount
        ]
    }
    
    public var authorLink: AO3AuthorLink { return AO3AuthorLink(id: username, pseudID: username, displayedName: username, profilePicture: profilePicture) }
    
    public struct AO3SignedInUserMetadata: Identifiable, Sendable, Codable, Hashable {
        public let id: Int
        
        public var inboxCount: Int
        
        public var signupCount: Int
        public var assignmentsCount: Int
        public var claimsCount: Int
        public var relatedWorksCount: Int
        
        public var countDictionary: [String: Int] {
            return [
                "Inbox": self.inboxCount,
                "Sign-Ups": self.signupCount,
                "Assignments": self.assignmentsCount,
                "Claims": self.claimsCount,
                "Related Works": self.relatedWorksCount
            ]
        }
    }
    
    public var isCurrentUser: Bool { self.signedInMetadata != nil }
}

// MARK: - AO3ProfileImage

public struct AO3Image: Identifiable, Sendable, Codable, Hashable {
    public var description: String?
    public var source: String
    
    public var url: URL? { return URL(string: self.source) }
    
    public var id: String { self.source }
    
    public var isDefault: Bool {
        self.source.contains("/images/skins/iconsets/default/icon_user.png")
    }
}
