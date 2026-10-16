//
//  AO3ChapterCommentThread.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 15.09.2026.
//

import Foundation


public struct AO3ChapterCommentThread: Identifiable, Codable, Hashable, Sendable, AO3Response {
    public var id: Int // html id="comment_[ID]"
    public var rootComment: AO3ChapterComment
    public var replies: [AO3ChapterCommentThread]?
    
    public var totalCommentsCount: Int {
        self.childCommentsCount + 1
    }
    
    public var childCommentsCount: Int {
        if let replies {
            return replies.reduce(0) { $0 + $1.totalCommentsCount }
        } else { return 0 }
    }
    
    public static var responseType: ResponseType { return .commentThread }
}

public struct AO3ChapterComment: Identifiable, Codable, Hashable, Sendable, AO3Response {
    public var id: Int
    public var user: AO3CommenterType?
    
    public var ao3userID: Int?
    
    public var postDate: Date
    public var lastEdited: Date?
    
    public var contentHTML: String
    
    public var chapter: AO3ChapterLink?
    
    public var isDeleted: Bool
    
    public static var responseType: ResponseType { return .comment }
}

public enum AO3CommenterType: Codable, Hashable, Sendable {
    case registered(link: AO3AuthorLink)
    case guest(name: String)
    
    public var displayName: String {
        switch self {
        case .registered(let link): return link.displayedName
        case .guest(let name): return name
        }
    }
}

public extension Array where Element == AO3ChapterCommentThread {
    var totalCommentsCount: Int {
        return self.reduce(0) { $0 + $1.totalCommentsCount }
    }
}


public struct AO3CommentLink: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public var id: Int
    
    public var workID: Int
    public var index: Int
    
    public var workTitle: String
    
    public static var responseType: ResponseType { return .comment }
}
