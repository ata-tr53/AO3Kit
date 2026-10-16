//
//  AO3BookmarkPreview.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 15.09.2026.
//

import Foundation

public struct AO3BookmarkPreview: Identifiable, Sendable, Codable, AO3Response {
    /// A local UUID since these short blurbs do not expose a native AO3 Bookmark ID.
    public var id: UUID = UUID()
    
    public var user: AO3AuthorLink
    public var bookmarkDate: Date
    public var status: [AO3BookmarkStatus]
    public var collections: [AO3CollectionLink]
    
    public var notes: String?
    
    public static var responseType: ResponseType { return .bookmark }
}
