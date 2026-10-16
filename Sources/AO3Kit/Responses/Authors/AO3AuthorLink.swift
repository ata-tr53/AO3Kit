//
//  AO3AuthorLink.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 15.09.2026.
//

import Foundation


public struct AO3AuthorLink: Identifiable, Sendable, Codable, Hashable, AO3Response {
    /// /users/[id]/pseuds/[pseudID]
    public var id: String
    
    public var pseudID: String
    
    /// Can be either "pseudDisplayName (actualName)" or "actualName"
    public var displayedName: String
    
    public var profilePicture: AO3Image?
    
    public static var responseType: ResponseType { return .user }
    
    public var url: URL? {
        return URL(string: "https://archiveofourown.org/users/\(id)")
    }
    
    public var profileURL: URL? {
        return URL(string: "https://archiveofourown.org/users/\(id)/profile")
    }
    
    public var profileImageURL: URL? {
        return self.profilePicture?.url ?? URL(string: "https://archiveofourown.org/images/skins/iconsets/default/icon_user.png")
    }
    
    public init(id: String, pseudID: String, displayedName: String, profilePicture: AO3Image? = nil) {
        self.id = id
        self.pseudID = pseudID
        self.displayedName = displayedName
        self.profilePicture = profilePicture
    }
}

public struct AO3MutedBlockedLink: Identifiable, Sendable, Codable, Hashable, AO3Response, AO3Mutable, AO3Blockable {
    public var id: String { return authorLink.id }
    public var username: String { return authorLink.id }
    public static var responseType: ResponseType { return AO3AuthorLink.responseType }
    
    public var authorLink: AO3AuthorLink
    
    public var unmuteActionID: Int?
    public var unblockActionID: Int?
}
