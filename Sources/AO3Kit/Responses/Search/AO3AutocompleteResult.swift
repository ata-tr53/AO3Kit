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
    /// Collections (returns collection ID in `id` and `"id - title"` in `name`).
    case collection
    /// User pseudonyms.
    case pseud
    
    internal var pathComponent: String {
        switch self {
        case .allTags: return "tag"
        case .fandom: return "fandom"
        case .character(let fandoms):
            return fandoms.isEmpty ? "character" : "character_in_fandom"
        case .relationship(let fandoms):
            return fandoms.isEmpty ? "relationship" : "relationship_in_fandom"
        case .freeform: return "freeform"
        case .collection: return "collection_title"
        case .pseud: return "pseud"
        }
    }
    
    internal func queryItems(for term: String) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "term", value: term)]
        switch self {
        case .character(let fandoms), 
                .relationship(let fandoms) where !fandoms.isEmpty:
            items.append(URLQueryItem(name: "fandom", value: fandoms.joined(separator: ",")))
        default:
            break
        }
        return items
    }
}
