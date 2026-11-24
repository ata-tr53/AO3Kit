//
//  AO3AutocompleteResult.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

public struct AO3AutocompleteResult: Identifiable, Sendable, Codable, Hashable, AO3Response {
    /// The canonical value or slug (e.g., tag name, or collection short ID like "yuletide2025").
    public let id: String
    
    /// The human-readable label (for collections, formatted as "slug - Display Title").
    public let name: String
    
    public static var responseType: ResponseType { .autocomplete }
}

public enum AO3AutocompleteScope: Sendable, Equatable, Hashable {
    /// All canonical tags across every category.
    case allTags
    /// Canonical fandom tags.
    case fandom
    /// Canonical character tags, optionally filtered to one or more fandoms.
    case character(inFandoms: [String] = [])
    /// Canonical relationship tags, optionally filtered to one or more fandoms.
    case relationship(inFandoms: [String] = [])
    /// Canonical freeform (additional) tags.
    case freeform
    /// Non-canonical tags, optionally filtered by tag type.
    case noncanonicalTag(type: AO3TagSearchFilter.TagType? = nil)
    /// Tags associated with specific fandoms, optionally filtered by tag type.
    case associatedTags(fandoms: [String] = [], type: AO3TagSearchFilter.TagType? = nil)
    /// Tags belonging to one or more tag sets, optionally filtered by tag type and fandoms.
    case tagsInSets(tagSetIDs: [Int], type: AO3TagSearchFilter.TagType? = nil, fandoms: [String] = [])
    /// Collections by title (returns collection ID in `id` and `"id - title"` in `name`).
    case collection
    /// Open collection names.
    case openCollectionNames
    /// Parent collection names.
    case collectionParentName
    /// User pseudonyms.
    case pseud
    /// External works.
    case externalWork
    /// Potential offers in a gift exchange or prompt meme collection.
    case potentialOffers(collectionID: Int)
    /// Potential requests in a gift exchange or prompt meme collection.
    case potentialRequests(collectionID: Int)
    /// Tag sets owned by the current user.
    case ownedTagSets
    /// Site skins.
    case siteSkins
    /// Admin (news) posts.
    case adminPosts
    /// Admin post tags.
    case adminPostTags

    internal var endpointType: AO3AutocompleteType {
        switch self {
        case .allTags: return .tag
        case .fandom: return .fandom
        case .character(let fandoms):
            return fandoms.isEmpty ? .character : .characterInFandom
        case .relationship(let fandoms):
            return fandoms.isEmpty ? .relationship : .relationshipInFandom
        case .freeform: return .freeform
        case .noncanonicalTag: return .noncanonicalTag
        case .associatedTags: return .associatedTags
        case .tagsInSets: return .tagsInSets
        case .collection: return .collectionTitle
        case .openCollectionNames: return .openCollectionNames
        case .collectionParentName: return .collectionParentName
        case .pseud: return .pseud
        case .externalWork: return .externalWork
        case .potentialOffers: return .potentialOffers
        case .potentialRequests: return .potentialRequests
        case .ownedTagSets: return .ownedTagSets
        case .siteSkins: return .siteSkins
        case .adminPosts: return .adminPosts
        case .adminPostTags: return .adminPostTags
        }
    }

    internal var pathComponent: String {
        endpointType.rawValue
    }

    internal func queryItems(for term: String) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "term", value: term)]
        switch self {
        case .character(let fandoms) where !fandoms.isEmpty,
             .relationship(let fandoms) where !fandoms.isEmpty:
            items.append(URLQueryItem(name: "fandom", value: fandoms.joined(separator: ",")))
        case .noncanonicalTag(let type):
            if let type {
                items.append(URLQueryItem(name: "type", value: type.rawValue))
            }
        case .associatedTags(let fandoms, let type):
            if !fandoms.isEmpty {
                items.append(URLQueryItem(name: "fandom", value: fandoms.joined(separator: ",")))
            }
            if let type {
                items.append(URLQueryItem(name: "type", value: type.rawValue))
            }
        case .tagsInSets(let tagSetIDs, let type, let fandoms):
            if !tagSetIDs.isEmpty {
                items.append(URLQueryItem(name: "tag_set", value: tagSetIDs.map(String.init).joined(separator: ",")))
            }
            if let type {
                items.append(URLQueryItem(name: "type", value: type.rawValue))
            }
            if !fandoms.isEmpty {
                items.append(URLQueryItem(name: "fandom", value: fandoms.joined(separator: ",")))
            }
        case .potentialOffers(let collectionID),
             .potentialRequests(let collectionID):
            items.append(URLQueryItem(name: "collection_id", value: String(collectionID)))
        default:
            break
        }
        return items
    }
}
