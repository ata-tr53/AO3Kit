//
//  AO3FicBookmark.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

public struct AO3FicBookmark: Identifiable, Sendable, Codable, AO3Response {
    public var id: Int
    
    public var ficPreview: AO3FicPreview?
    
    public var user: AO3AuthorLink
    public var tags: [String]
    public var bookmarkDate: Date
    public var status: [AO3BookmarkStatus]
    public var collections: [AO3CollectionLink]
    
    public var notes: String?
    
    public static var responseType: ResponseType { return .bookmark }
}

public enum AO3BookmarkStatus: String, Sendable, Codable {
    /// Recommended
    case rec
    
    /// Public Bookmark
    case `public`
    
    /// Private Bookmark
    case `private`
    
    /// This bookmark has been hidden by an admin.
    case hidden
    
    public var displayName: LocalizedStringResource {
        switch self {
        case .rec: return "Recommended"
        case .public: return "Public Bookmark"
        case .private: return "Private Bookmark"
        case .hidden: return "Hidden"
        }
    }
    
    public var displaySymbol: String {
        switch self {
        case .rec: return "star.fill"
        case .public: return "eye.fill"
        case .private: return "lock.fill"
        case .hidden: return "eye.slash.fill"
        }
    }
}
