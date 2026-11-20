//
//  AO3Commentable.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

public enum AO3CommentableType: String, Sendable, Codable, Hashable {
    case work = "Work"
    case chapter = "Chapter"
    case adminPost = "AdminPost"
    case comment = "Comment"
}

public protocol AO3Commentable: AO3Response {
    var commentableID: Int { get }
    var commentableType: AO3CommentableType { get }
    var commentsEndpoint: AO3Endpoint { get }
    var commentHostEndpoint: AO3Endpoint { get }
    var postCommentEndpoint: AO3Endpoint { get }
}

public extension AO3Commentable {
    var commentsEndpoint: AO3Endpoint {
        switch commentableType {
        case .work:
            return .work(id: commentableID, route: .comments)
        case .chapter:
            return .chapter(id: commentableID, route: .comments)
        case .adminPost:
            return .news(id: commentableID, route: .comments)
        case .comment:
            return .commentThread(id: commentableID)
        }
    }

    var commentHostEndpoint: AO3Endpoint {
        switch commentableType {
        case .work:
            return .work(id: commentableID, route: .main)
        case .chapter:
            return .chapter(id: commentableID, route: .main)
        case .adminPost:
            return .news(id: commentableID, route: .main)
        case .comment:
            return .commentThread(id: commentableID)
        }
    }

    var postCommentEndpoint: AO3Endpoint {
        switch commentableType {
        case .work:
            return .work(id: commentableID, route: .comments(.index))
        case .chapter:
            return .chapter(id: commentableID, route: .comments(.index))
        case .adminPost:
            return .news(id: commentableID, route: .comments(.index))
        case .comment:
            return .comments(.replies(commentID: commentableID, action: .index))
        }
    }
}

public protocol AO3ModerableComment: AO3Response {
    var commentID: Int { get }
}

// MARK: - Default Conformances

extension AO3ChapterLink: AO3Commentable {
    public var commentableID: Int { id }
    public var commentableType: AO3CommentableType { .chapter }
}

extension AO3AdminPost: AO3Commentable {
    public var commentableID: Int { id }
    public var commentableType: AO3CommentableType { .adminPost }
}

extension AO3ChapterCommentThread: AO3Commentable, AO3ModerableComment {
    public var commentableID: Int { id }
    public var commentableType: AO3CommentableType { .comment }
    public var commentID: Int { id }
}

extension AO3ChapterComment: AO3Commentable, AO3ModerableComment {
    public var commentableID: Int { id }
    public var commentableType: AO3CommentableType { .comment }
    public var commentID: Int { id }
}

extension AO3CommentLink: AO3ModerableComment {
    public var commentID: Int { id }
}
