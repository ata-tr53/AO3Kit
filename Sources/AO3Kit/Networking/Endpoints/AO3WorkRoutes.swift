//
//  AO3WorkRoutes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

// MARK: - Work Routes
public enum AO3WorksCollectionRoute: Equatable, Sendable {
    case index
    case new
    case `import`
    case cleanWorkSearchParams
    case collected
    case drafts
    case editMultiple(id: Int)
    case confirmDeleteMultiple(id: Int)
    case deleteMultiple(id: Int)
    case updateMultiple

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .import: return "/import"
        case .cleanWorkSearchParams: return "/clean_work_search_params"
        case .collected: return "/collected"
        case .drafts: return "/drafts"
        case .editMultiple(let id): return "/edit_multiple/\(id)"
        case .confirmDeleteMultiple(let id): return "/confirm_delete_multiple/\(id)"
        case .deleteMultiple(let id): return "/delete_multiple/\(id)"
        case .updateMultiple: return "/update_multiple"
        }
    }
}

public enum AO3WorkRoute: Equatable, Sendable {
    case main
    case fullWork
    case edit
    case preview
    case post
    case postDraft
    case navigate
    case removeUserCreatorship
    case editTags
    case updateTags
    case markForLater
    case markAsRead
    case confirmDelete
    case share
    case hitCount
    case kudos
    case troubleshooting

    case bookmarks(AO3ResourceAction<Int> = .index)
    case chapters(AO3WorkChaptersRoute)
    case chapter(id: Int)
    case collections(AO3ResourceAction<String> = .index)
    case collectionItems(AO3ResourceAction<Int> = .index)
    case comments(AO3ModeratedCommentsRoute = .index)

    public var pathSuffix: String {
        switch self {
        case .main, .fullWork: return ""
        case .edit: return "/edit"
        case .preview: return "/preview"
        case .post: return "/post"
        case .postDraft: return "/post_draft"
        case .navigate: return "/navigate"
        case .removeUserCreatorship: return "/remove_user_creatorship"
        case .editTags: return "/edit_tags"
        case .updateTags: return "/update_tags"
        case .markForLater: return "/mark_for_later"
        case .markAsRead: return "/mark_as_read"
        case .confirmDelete: return "/confirm_delete"
        case .share: return "/share"
        case .hitCount: return "/hit_count"
        case .kudos: return "/kudos"
        case .troubleshooting: return "/troubleshooting"
        case .bookmarks(let action): return "/bookmarks" + action.pathSuffix
        case .chapters(let route): return "/chapters" + route.pathSuffix
        case .chapter(let id): return "/chapters/\(id)"
        case .collections(let action): return "/collections" + action.pathSuffix
        case .collectionItems(let action): return "/collection_items" + action.pathSuffix
        case .comments(let route): return "/comments" + route.pathSuffix
        }
    }

    public var queryItems: [URLQueryItem] {
        switch self {
        case .comments(.index): return [URLQueryItem(name: "show_comments", value: "true")]
        case .fullWork: return [URLQueryItem(name: "view_full_work", value: "true")]
        default: return []
        }
    }

    static func dissect(remainder: [String], queryItems: [URLQueryItem]? = nil) -> AO3WorkRoute {
        guard let first = remainder.first else {
            if queryItems?.contains(where: { $0.name == "view_full_work" && $0.value == "true" }) == true {
                return .fullWork
            }
            if queryItems?.contains(where: { $0.name == "show_comments" && $0.value == "true" }) == true {
                return .comments(.index)
            }
            return .main
        }
        let rest = Array(remainder.dropFirst())
        switch first {
        case "edit": return .edit
        case "preview": return .preview
        case "post": return .post
        case "post_draft": return .postDraft
        case "navigate": return .navigate
        case "remove_user_creatorship": return .removeUserCreatorship
        case "edit_tags": return .editTags
        case "update_tags": return .updateTags
        case "mark_for_later": return .markForLater
        case "mark_as_read": return .markAsRead
        case "confirm_delete": return .confirmDelete
        case "share": return .share
        case "hit_count": return .hitCount
        case "kudos": return .kudos
        case "troubleshooting": return .troubleshooting
        case "bookmarks":
            return .bookmarks(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        case "collections":
            return .collections(AO3ResourceAction.dissect(remainder: rest, parseID: { $0 }) ?? .index)
        case "collection_items":
            return .collectionItems(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        case "comments":
            return .comments(AO3ModeratedCommentsRoute.dissect(remainder: rest))
        case "chapters":
            if rest.isEmpty { return .chapters(.index) }
            if rest[0] == "new" { return .chapters(.new) }
            if rest[0] == "manage" { return .chapters(.manage) }
            if rest[0] == "update_positions" { return .chapters(.updatePositions) }
            if let cid = Int(rest[0]) {
                let cRest = Array(rest.dropFirst())
                guard let sub = cRest.first else { return .chapter(id: cid) }
                switch sub {
                case "edit": return .chapters(.edit(id: cid))
                case "preview": return .chapters(.preview(id: cid))
                case "post": return .chapters(.post(id: cid))
                case "confirm_delete": return .chapters(.confirmDelete(id: cid))
                case "comments":
                    let action = AO3ResourceAction.dissect(remainder: Array(cRest.dropFirst()), parseID: Int.init) ?? .index
                    return .chapters(.comments(chapterID: cid, action: action))
                default: return .chapter(id: cid)
                }
            }
            return .main
        default:
            return .main
        }
    }
}

public extension AO3WorkRoute {
    static var bookmarks: AO3WorkRoute { .bookmarks(.index) }
    static var comments: AO3WorkRoute { .comments(.index) }
}

public enum AO3WorkChaptersRoute: Equatable, Sendable {
    case index
    case new
    case manage
    case updatePositions
    case show(id: Int)
    case edit(id: Int)
    case preview(id: Int)
    case post(id: Int)
    case confirmDelete(id: Int)
    case comments(chapterID: Int, action: AO3ResourceAction<Int>)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .manage: return "/manage"
        case .updatePositions: return "/update_positions"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .preview(let id): return "/\(id)/preview"
        case .post(let id): return "/\(id)/post"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        case .comments(let cid, let action): return "/\(cid)/comments" + action.pathSuffix
        }
    }
}

public enum AO3ModeratedCommentsRoute: Equatable, Sendable {
    case index
    case new
    case unreviewed
    case reviewAll
    case show(id: Int)
    case edit(id: Int)
    case approve(id: Int)
    case reject(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .unreviewed: return "/unreviewed"
        case .reviewAll: return "/review_all"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .approve(let id): return "/\(id)/approve"
        case .reject(let id): return "/\(id)/reject"
        }
    }

    static func dissect(remainder: [String]) -> Self {
        guard let first = remainder.first else { return .index }
        switch first {
        case "new": return .new
        case "unreviewed": return .unreviewed
        case "review_all": return .reviewAll
        default:
            guard let id = Int(first) else { return .index }
            switch remainder.dropFirst().first {
            case "edit": return .edit(id: id)
            case "approve": return .approve(id: id)
            case "reject": return .reject(id: id)
            default: return .show(id: id)
            }
        }
    }
}

// MARK: - Chapter Routes (Top-level /chapters/:id)
public enum AO3ChapterRoute: Equatable, Sendable {
    case main
    case edit
    case preview
    case post
    case removeUserCreatorship
    case comments(AO3ResourceAction<Int> = .index)

    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .edit: return "/edit"
        case .preview: return "/preview"
        case .post: return "/post"
        case .removeUserCreatorship: return "/remove_user_creatorship"
        case .comments(let action): return "/comments" + action.pathSuffix
        }
    }

    public var queryItems: [URLQueryItem] {
        if case .comments(.index) = self {
            return [URLQueryItem(name: "show_comments", value: "true")]
        }
        return []
    }

    static func dissect(remainder: [String], queryItems: [URLQueryItem]? = nil) -> AO3ChapterRoute {
        guard let first = remainder.first else {
            if queryItems?.contains(where: { $0.name == "show_comments" && $0.value == "true" }) == true {
                return .comments(.index)
            }
            return .main
        }
        switch first {
        case "edit": return .edit
        case "preview": return .preview
        case "post": return .post
        case "remove_user_creatorship": return .removeUserCreatorship
        case "comments":
            let action = AO3ResourceAction.dissect(remainder: Array(remainder.dropFirst()), parseID: Int.init) ?? .index
            return .comments(action)
        default: return .main
        }
    }
}

public extension AO3ChapterRoute {
    static var comments: AO3ChapterRoute { .comments(.index) }
}
