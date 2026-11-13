//
//  AO3AuthorPseudLink.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

public struct AO3AuthorPseudLink: Codable, Sendable, Hashable, Identifiable, AO3AuthorModel, AO3IconPresentable {
    public var id: String { "\(username)/\(pseudName)" }
    
    /// The parent AO3 account username (used for `/users/{username}` endpoints).
    public var username: String
    
    /// The display name of the pseudonym itself.
    public var pseudName: String
    
    public var summary: String?
    public var icon: AO3Image?
    public var workCount: Int?
    
    public static var responseType: ResponseType { return .user }
}
