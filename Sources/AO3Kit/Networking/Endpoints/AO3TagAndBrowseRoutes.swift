//
//  AO3TagAndBrowseRoutes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

// MARK: - Tag Routes
public enum AO3TagsCollectionRoute: Equatable, Sendable {
    case index, new, showHidden

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .showHidden: return "/show_hidden"
        }
    }
}

public enum AO3TagRoute: Equatable, Sendable {
    case main
    case edit
    case feed(atom: Bool = false)
    case massUpdate
    case removeAssociation
    case wrangle
    case troubleshooting
    case works(AO3ResourceAction<Int> = .index)
    case bookmarks(AO3ResourceAction<Int> = .index)
    case comments(AO3ResourceAction<Int> = .index)

    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .edit: return "/edit"
        case .feed(let atom): return atom ? "/feed.atom" : "/feed"
        case .massUpdate: return "/mass_update"
        case .removeAssociation: return "/remove_association"
        case .wrangle: return "/wrangle"
        case .troubleshooting: return "/troubleshooting"
        case .works(let action): return "/works" + action.pathSuffix
        case .bookmarks(let action): return "/bookmarks" + action.pathSuffix
        case .comments(let action): return "/comments" + action.pathSuffix
        }
    }

    public var queryItems: [URLQueryItem] { [] }

    static func dissect(remainder: [String]) -> AO3TagRoute {
        guard let first = remainder.first else { return .main }
        let rest = Array(remainder.dropFirst())
        switch first {
        case "edit": return .edit
        case "feed": return .feed(atom: false)
        case "feed.atom": return .feed(atom: true)
        case "mass_update": return .massUpdate
        case "remove_association": return .removeAssociation
        case "wrangle": return .wrangle
        case "troubleshooting": return .troubleshooting
        case "works": return .works(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        case "bookmarks": return .bookmarks(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        case "comments": return .comments(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        default: return .main
        }
    }
}

public extension AO3TagRoute {
    static var feed: AO3TagRoute { .feed(atom: false) }
    static var works: AO3TagRoute { .works(.index) }
    static var bookmarks: AO3TagRoute { .bookmarks(.index) }
}

// MARK: - Autocomplete (All 21 Actions in routes.txt)
public enum AO3AutocompleteType: Equatable, Sendable {
    case pseud, tag, fandom, character, relationship, freeform
    case characterInFandom, relationshipInFandom, tagsInSets
    case associatedTags, noncanonicalTag, collectionTitle
    case openCollectionNames, collectionParentName, externalWork
    case potentialOffers, potentialRequests, ownedTagSets
    case siteSkins, adminPosts, adminPostTags
    case other(String)

    public init(rawValue: String) {
        switch rawValue {
        case "pseud": self = .pseud
        case "tag": self = .tag
        case "fandom": self = .fandom
        case "character": self = .character
        case "relationship": self = .relationship
        case "freeform": self = .freeform
        case "character_in_fandom": self = .characterInFandom
        case "relationship_in_fandom": self = .relationshipInFandom
        case "tags_in_sets": self = .tagsInSets
        case "associated_tags": self = .associatedTags
        case "noncanonical_tag": self = .noncanonicalTag
        case "collection_title": self = .collectionTitle
        case "open_collection_names": self = .openCollectionNames
        case "collection_parent_name": self = .collectionParentName
        case "external_work": self = .externalWork
        case "potential_offers": self = .potentialOffers
        case "potential_requests": self = .potentialRequests
        case "owned_tag_sets": self = .ownedTagSets
        case "site_skins": self = .siteSkins
        case "admin_posts": self = .adminPosts
        case "admin_post_tags": self = .adminPostTags
        default: self = .other(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .pseud: return "pseud"
        case .tag: return "tag"
        case .fandom: return "fandom"
        case .character: return "character"
        case .relationship: return "relationship"
        case .freeform: return "freeform"
        case .characterInFandom: return "character_in_fandom"
        case .relationshipInFandom: return "relationship_in_fandom"
        case .tagsInSets: return "tags_in_sets"
        case .associatedTags: return "associated_tags"
        case .noncanonicalTag: return "noncanonical_tag"
        case .collectionTitle: return "collection_title"
        case .openCollectionNames: return "open_collection_names"
        case .collectionParentName: return "collection_parent_name"
        case .externalWork: return "external_work"
        case .potentialOffers: return "potential_offers"
        case .potentialRequests: return "potential_requests"
        case .ownedTagSets: return "owned_tag_sets"
        case .siteSkins: return "site_skins"
        case .adminPosts: return "admin_posts"
        case .adminPostTags: return "admin_post_tags"
        case .other(let v): return v
        }
    }
}

// MARK: - Media, Fandoms, Wrangling & Tag Sets
public enum AO3MediaRoute: Equatable, Sendable {
    case index, new
    case show(id: String)
    case edit(id: String)
    case fandoms(mediaID: String, action: AO3ResourceAction<String>)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .fandoms(let mid, let action): return "/\(mid)/fandoms" + action.pathSuffix
        }
    }
}

public enum AO3FandomRoute: Equatable, Sendable {
    case index, new, unassigned
    case show(id: String)
    case edit(id: String)
    case explicitShow(id: String)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .unassigned: return "/unassigned"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .explicitShow(let id): return "/\(id)/show"
        }
    }
}

public enum AO3TagWranglingRoute: Equatable, Sendable {
    case index, new, wrangle
    case show(id: Int)
    case edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .wrangle: return "/wrangle"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3TagWranglerRoute: Equatable, Sendable {
    case index, new
    case show(id: String)
    case edit(id: String)
    case reportCSV(id: String)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .reportCSV(let id): return "/\(id)/report_csv"
        }
    }
}

public enum AO3UnsortedTagsRoute: Equatable, Sendable {
    case index, new, massUpdate
    case show(id: Int)
    case edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .massUpdate: return "/mass_update"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3TagSetRoute: Equatable, Sendable {
    case index, new, showOptions
    case show(id: Int)
    case edit(id: Int)
    case batchLoad(id: Int)
    case doBatchLoad(id: Int)
    case confirmDelete(id: Int)
    case nominations(tagSetID: Int, route: AO3TagSetNominationsRoute)
    case associations(tagSetID: Int, updateMultiple: Bool)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .showOptions: return "/show_options"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .batchLoad(let id): return "/\(id)/batch_load"
        case .doBatchLoad(let id): return "/\(id)/do_batch_load"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        case .nominations(let tid, let route): return "/\(tid)/nominations" + route.pathSuffix
        case .associations(let tid, let multi): return "/\(tid)/associations" + (multi ? "/update_multiple" : "")
        }
    }
}

public enum AO3TagSetNominationsRoute: Equatable, Sendable {
    case index, new, updateMultiple, destroyMultiple, confirmDestroyMultiple
    case show(id: Int)
    case edit(id: Int)
    case confirmDelete(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .updateMultiple: return "/update_multiple"
        case .destroyMultiple: return "/destroy_multiple"
        case .confirmDestroyMultiple: return "/confirm_destroy_multiple"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        }
    }
}

public enum AO3TagWranglingRequestsRoute: Equatable, Sendable {
    case index, updateMultiple
    public var pathSuffix: String { self == .updateMultiple ? "/update_multiple" : "" }
}

public enum AO3ManagedArticleRoute: Equatable, Sendable {
    case index, new, manage, updatePositions
    case show(id: Int), edit(id: Int), confirmDelete(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .manage: return "/manage"
        case .updatePositions: return "/update_positions"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        }
    }
}
