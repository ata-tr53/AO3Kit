//
//  AO3CommunityRoutes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

// MARK: - Series Routes
public enum AO3SeriesRoute: Equatable, Sendable {
    case main
    case edit
    case confirmDelete
    case manage
    case updatePositions
    case removeUserCreatorship
    case bookmarks(AO3ResourceAction<Int> = .index)

    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .edit: return "/edit"
        case .confirmDelete: return "/confirm_delete"
        case .manage: return "/manage"
        case .updatePositions: return "/update_positions"
        case .removeUserCreatorship: return "/remove_user_creatorship"
        case .bookmarks(let action): return "/bookmarks" + action.pathSuffix
        }
    }

    public var queryItems: [URLQueryItem] { [] }

    static func dissect(remainder: [String]) -> AO3SeriesRoute {
        guard let first = remainder.first else { return .main }
        let rest = Array(remainder.dropFirst())
        switch first {
        case "edit": return .edit
        case "confirm_delete": return .confirmDelete
        case "manage": return .manage
        case "update_positions": return .updatePositions
        case "remove_user_creatorship": return .removeUserCreatorship
        case "bookmarks": return .bookmarks(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        default: return .main
        }
    }
}

public extension AO3SeriesRoute {
    static var bookmarks: AO3SeriesRoute { .bookmarks(.index) }
}

// MARK: - News (Admin Posts) Routes
public enum AO3NewsRoute: Equatable, Sendable {
    case main
    case drafts
    case new
    case edit
    case post
    case preview
    case comments(AO3NewsCommentsRoute = .index)

    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .drafts, .new: return ""
        case .edit: return "/edit"
        case .post: return "/post"
        case .preview: return "/preview"
        case .comments(let route): return "/comments" + route.pathSuffix
        }
    }

    internal var newsCollectionSuffix: String {
        switch self {
        case .drafts: return "/drafts"
        case .new: return "/new"
        default: return ""
        }
    }

    public var queryItems: [URLQueryItem] { [] }

    public static func dissect(remainder: [String]) -> AO3NewsRoute {
        guard let first = remainder.first else { return .main }
        let rest = Array(remainder.dropFirst())
        switch first {
        case "edit": return .edit
        case "post": return .post
        case "preview": return .preview
        case "comments":
            switch rest.first {
            case "new": return .comments(.new)
            case "unreviewed": return .comments(.unreviewed)
            case "review_all": return .comments(.reviewAll)
            case let s? where Int(s) != nil:
                let cid = Int(s)!
                return .comments(rest.dropFirst().first == "edit" ? .edit(id: cid) : .show(id: cid))
            default: return .comments(.index)
            }
        default: return .main
        }
    }
}

public extension AO3NewsRoute {
    static var comments: AO3NewsRoute { .comments(.index) }
}

public enum AO3NewsCommentsRoute: Equatable, Sendable {
    case index, new, unreviewed, reviewAll
    case show(id: Int)
    case edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .unreviewed: return "/unreviewed"
        case .reviewAll: return "/review_all"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

// MARK: - Bookmarks & Comments
public enum AO3BookmarkRoute: Equatable, Sendable {
    case index, new
    case show(id: Int)
    case edit(id: Int)
    case confirmDelete(id: Int)
    case share(id: Int)
    case collectionItems(bookmarkID: Int, action: AO3ResourceAction<Int>)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        case .share(let id): return "/\(id)/share"
        case .collectionItems(let bid, let action): return "/\(bid)/collection_items" + action.pathSuffix
        }
    }
}

public enum AO3CommentRoute: Equatable, Sendable {
    case index, new
    case hideComments, showComments, addCommentReply
    case cancelCommentReply, cancelCommentEdit, deleteComment, cancelCommentDelete
    case edit(id: Int)
    case approve(id: Int), reject(id: Int), review(id: Int)
    case freeze(id: Int), unfreeze(id: Int)
    case hide(id: Int), unhide(id: Int)
    case replies(commentID: Int, action: AO3ResourceAction<Int>)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .hideComments: return "/hide_comments"
        case .showComments: return "/show_comments"
        case .addCommentReply: return "/add_comment_reply"
        case .cancelCommentReply: return "/cancel_comment_reply"
        case .cancelCommentEdit: return "/cancel_comment_edit"
        case .deleteComment: return "/delete_comment"
        case .cancelCommentDelete: return "/cancel_comment_delete"
        case .edit(let id): return "/\(id)/edit"
        case .approve(let id): return "/\(id)/approve"
        case .reject(let id): return "/\(id)/reject"
        case .review(let id): return "/\(id)/review"
        case .freeze(let id): return "/\(id)/freeze"
        case .unfreeze(let id): return "/\(id)/unfreeze"
        case .hide(let id): return "/\(id)/hide"
        case .unhide(let id): return "/\(id)/unhide"
        case .replies(let cid, let action): return "/\(cid)/comments" + action.pathSuffix
        }
    }
}

public enum AO3PeopleRoute: Equatable, Sendable {
    case index
    public var pathSuffix: String { "" }
}

// MARK: - External Works, Authors, Gifts, Invitations
public enum AO3ExternalWorkRoute: Equatable, Sendable {
    case index, new, fetch
    case show(id: Int), edit(id: Int)
    case bookmarks(externalWorkID: Int, action: AO3ResourceAction<Int>)
    case relatedWorks(externalWorkID: Int, action: AO3ResourceAction<Int>)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .fetch: return "/fetch"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .bookmarks(let eid, let action): return "/\(eid)/bookmarks" + action.pathSuffix
        case .relatedWorks(let eid, let action): return "/\(eid)/related_works" + action.pathSuffix
        }
    }
}

public enum AO3ExternalAuthorRoute: Equatable, Sendable {
    case index, new
    case show(id: Int), edit(id: Int)
    case names(authorID: Int, action: AO3ResourceAction<Int>)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .names(let aid, let action): return "/\(aid)/external_author_names" + action.pathSuffix
        }
    }

    static func dissect(remainder: [String]) -> Self {
        guard let first = remainder.first else { return .index }
        if first == "new" { return .new }
        guard let id = Int(first) else { return .index }
        let rest = Array(remainder.dropFirst())
        switch rest.first {
        case "edit": return .edit(id: id)
        case "external_author_names":
            let action = AO3ResourceAction.dissect(remainder: Array(rest.dropFirst()), parseID: Int.init) ?? .index
            return .names(authorID: id, action: action)
        default: return .show(id: id)
        }
    }
}

public enum AO3GiftRoute: Equatable, Sendable {
    case index
    case toggleRejected(id: Int)
    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .toggleRejected(let id): return "/\(id)/toggle_rejected"
        }
    }
}

public enum AO3ChallengeRoute: String, Equatable, Sendable {
    case noCollection = "no_collection"
    case noChallenge = "no_challenge"
    public var pathSuffix: String { "/\(rawValue)" }
}

public enum AO3UserInviteRequestRoute: Equatable, Sendable {
    case index, new, update
    case show(id: Int), edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .update: return "/update"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3InviteRequestRoute: Equatable, Sendable {
    case index, manage, status, resend, showAction
    case item(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .manage: return "/manage"
        case .status: return "/status"
        case .resend: return "/resend"
        case .showAction: return "/show"
        case .item(let id): return "/\(id)"
        }
    }
}
