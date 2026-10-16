//
//  AO3Endpoint.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

public enum AO3Endpoint: Equatable, Sendable {
    // MARK: - Core Domains
    case work(id: Int, route: AO3WorkRoute = .main)
    case user(username: String, route: AO3UserRoute = .profile)
    case collection(name: String, route: AO3CollectionRoute = .main)
    case tag(name: String, route: AO3TagRoute = .main)
    case series(id: Int, route: AO3SeriesRoute = .main)
    case chapter(id: Int, route: AO3ChapterRoute = .main)
    case commentThread(id: Int)
    
    // MARK: - Global Search & Discovery
    case worksSearch
    case tagsSearch
    case bookmarksSearch
    case peopleSearch
    case autocomplete(type: String)
    
    // MARK: - Standalone Features
    case download(workID: Int, title: String, format: String)
    case news(id: Int?, route: AO3NewsRoute = .main)
    case home
    case unknown
    
    public func url(page: Int? = nil, bypassAdultBlock: Bool = false) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "archiveofourown.org"
        
        var routeQueryItems: [URLQueryItem] = []
        
        switch self {
        case .work(let id, let route):
            components.path = "/works/\(id)" + route.pathSuffix
            routeQueryItems = route.queryItems
        case .user(let username, let route):
            components.path = "/users/\(username)" + route.pathSuffix
            routeQueryItems = route.queryItems
        case .collection(let name, let route):
            components.path = "/collections/\(name)" + route.pathSuffix
            routeQueryItems = route.queryItems
        case .tag(let name, let route):
            components.path = "/tags/\(name.ao3TagEncoded)" + route.pathSuffix
            routeQueryItems = route.queryItems
        case .series(let id, let route):
            components.path = "/series/\(id)" + route.pathSuffix
            routeQueryItems = route.queryItems
        case .chapter(let id, let route):
            components.path = "/chapters/\(id)" + route.pathSuffix
            routeQueryItems = route.queryItems
        case .commentThread(let id):
            components.path = "/comments/\(id)"
            
        case .worksSearch: components.path = "/works/search"
        case .tagsSearch: components.path = "/tags/search"
        case .bookmarksSearch: components.path = "/bookmarks/search"
        case .peopleSearch: components.path = "/people/search"
        case .autocomplete(let type): components.path = "/autocomplete/\(type)"
            
        case .download(let workID, let title, let format):
            // AO3 replaces spaces with underscores for the file title in URLs
            let safeTitle = title.replacingOccurrences(of: " ", with: "_")
            components.path = "/downloads/\(workID)/\(safeTitle).\(format)"
            
        case .news(let id, let route):
            if let id = id {
                components.path = "/admin_posts/\(id)" + route.pathSuffix
            } else {
                components.path = "/admin_posts"
            }
            routeQueryItems = route.queryItems
            
        case .home, .unknown: components.path = "/"
        }
        
        var allQueryItems = routeQueryItems
        
        if bypassAdultBlock {
            allQueryItems.append(URLQueryItem(name: "view_as", value: "adult"))
        }
        
        if let page = page, page > 1 {
            allQueryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        
        if !allQueryItems.isEmpty {
            components.queryItems = allQueryItems
        }
        
        return components.url
    }
}


// MARK: - Work Routes
public enum AO3WorkRoute: Equatable, Sendable {
    case main
    case fullWork
    case navigate // Chapter index
    case bookmarks // Handles GET (List) and POST (Create/Edit)
    case comments
    case chapter(id: Int)
    
    case kudos // POST
    case markForLater // PATCH
    case markAsRead // PATCH
    case hitCount // POST
    
    public var pathSuffix: String {
        switch self {
        case .main, .fullWork: return ""
        case .navigate: return "/navigate"
        case .bookmarks: return "/bookmarks"
        case .comments: return "/comments"
        case .kudos: return "/kudos"
        case .markForLater: return "/mark_for_later"
        case .markAsRead: return "/mark_as_read"
        case .hitCount: return "/hit_count"
        case .chapter(let id): return "/chapters/\(id)"
        }
    }
    
    public var queryItems: [URLQueryItem] {
        switch self {
        case .comments: return [URLQueryItem(name: "show_comments", value: "true")]
        case .fullWork: return [URLQueryItem(name: "view_full_work", value: "true")]
            
        default: return []
        }
    }
    
    static func dissect(remainder: [String]) -> AO3WorkRoute {
        guard let first = remainder.first else { return .main }
        
        switch first {
        case "navigate": return .navigate
        case "bookmarks": return .bookmarks
        case "comments": return .comments
        case "kudos": return .kudos
        case "mark_for_later": return .markForLater
        case "mark_as_read": return .markAsRead
        case "hit_count": return .hitCount
        case "chapters":
            if remainder.count > 1, let id = Int(remainder[1]) {
                return .chapter(id: id)
            } else { return .main }
        default: return .main
        }
    }
}

// MARK: - Chapter Routes
public enum AO3ChapterRoute: Equatable, Sendable {
    case main
    case comments
    
    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .comments: return "/comments"
        }
    }
    
    public var queryItems: [URLQueryItem] {
        switch self {
        case .comments:
            return [URLQueryItem(name: "show_comments", value: "true")]
        default:
            return []
        }
    }
}

// MARK: - User Routes
public enum AO3UserRoute: Equatable, Sendable {
    case profile
    case works
    case bookmarks
    case subscriptions
    case gifts
    case pseud(name: String)
    case muted
    case blocked
    case inbox
    case stats
    case series
    case allPseuds
    
    // History
    case history(showToRead: Bool = false) // GET
    case historyItem(id: Int) // DELETE
    case clearHistory // POST
    
    
    // Moderation POSTs
    case deleteSubscription(id: Int)
    case confirmMute(targetUsername: String)
    case confirmBlock(targetUsername: String)
    case favoriteTags // POST
    
    public var pathSuffix: String {
        switch self {
        case .profile: return "/profile"
        case .works: return "/works"
        case .bookmarks: return "/bookmarks"
        case .subscriptions: return "/subscriptions"
        case .gifts: return "/gifts"
        case .pseud(let name): return "/pseuds/\(name)"
        case .muted: return "/muted/users"
        case .blocked: return "/blocked/users"
        case .inbox: return "/inbox"
        case .stats: return "/stats"
        case .series: return "/series"
        case .allPseuds: return "/pseuds"
            
        case .history: return "/readings"
        case .historyItem(let id): return "/readings/\(id)"
        case .clearHistory: return "/readings/confirm_clear"
            
        case .deleteSubscription(let id): return "/subscriptions/\(id)"
        case .confirmMute: return "/muted/users/confirm_mute"
        case .confirmBlock: return "/blocked/users/confirm_block"
        case .favoriteTags: return "/favorite_tags"
        }
    }
    
    public var queryItems: [URLQueryItem] {
        switch self {
        case .history(let showToRead):
            return showToRead ? [URLQueryItem(name: "show", value: "to-read")] : []
        case .confirmMute(let target):
            return [URLQueryItem(name: "muted_id", value: target)]
        case .confirmBlock(let target):
            return [URLQueryItem(name: "blocked_id", value: target)]
        default:
            return []
        }
    }
    
    static func dissect(remainder: [String]) -> AO3UserRoute {
        guard let first = remainder.first else { return .profile }
        
        switch first {
        case "profile": return .profile
        case "works": return .works
        case "bookmarks": return .bookmarks
        case "subscriptions":
            if remainder.count > 1, let subID = Int(remainder[1]) {
                return .deleteSubscription(id: subID)
            }
            return .subscriptions
        case "gifts": return .gifts
        case "readings":
            if remainder.count > 1 {
                if remainder[1] == "clear" { return .clearHistory }
                if let historyID = Int(remainder[1]) { return .historyItem(id: historyID) }
            }
            return .history(showToRead: false)
        case "pseuds":
            if remainder.count > 1 { return .pseud(name: remainder[1]) }
            return .allPseuds
        case "favorite_tags": return .favoriteTags
        case "muted/users": return .muted
        case "blocked/users": return .blocked
        case "inbox": return .inbox
        case "stats": return .stats
        case "series": return .series
        default: return .profile
        }
    }
}

// MARK: - Collection Routes
public enum AO3CollectionRoute: Equatable, Sendable {
    case main
    case profile
    case works
    case bookmarks
    case tags
    case fandoms
    case media
    case people
    case collections
    
    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .profile: return "/profile"
        case .works: return "/works"
        case .bookmarks: return "/bookmarks"
        case .tags: return "/tags"
        case .fandoms: return "/fandoms"
        case .media: return "/media"
        case .people: return "/people"
        case .collections: return "/collections"
        }
    }
    
    public var queryItems: [URLQueryItem] { return [] }
    
    static func dissect(remainder: [String]) -> AO3CollectionRoute {
        guard let first = remainder.first else { return .main }
        
        switch first {
        case "works": return .works
        case "profile": return .profile
        case "bookmarks": return .bookmarks
        case "tags": return .tags
        case "fandoms": return .fandoms
        case "media": return .media
        case "people": return .people
        case "collections": return .collections
        default: return .main
        }
    }
}

// MARK: - Tag Routes
public enum AO3TagRoute: Equatable, Sendable {
    case main
    case works
    case bookmarks
    
    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .works: return "/works"
        case .bookmarks: return "/bookmarks"
        }
    }
    
    public var queryItems: [URLQueryItem] { return [] }
    
    static func dissect(remainder: [String]) -> AO3TagRoute {
        guard let first = remainder.first else { return .main }
        
        switch first {
        case "works": return .works
        case "bookmarks": return .bookmarks
        default: return .main
        }
    }
}

// MARK: - Series Routes
public enum AO3SeriesRoute: Equatable, Sendable {
    case main
    case bookmarks
    
    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .bookmarks: return "/bookmarks"
        }
    }
    
    public var queryItems: [URLQueryItem] { return [] }
    
    static func dissect(remainder: [String]) -> AO3SeriesRoute {
        guard let first = remainder.first else { return .main }
        if first == "bookmarks" { return .bookmarks }
        return .main
    }
}

// MARK: - News Routes
public enum AO3NewsRoute: Equatable, Sendable {
    case main
    case comments
    
    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .comments: return "/comments"
        }
    }
    
    public var queryItems: [URLQueryItem] { return [] }
    
    public static func dissect(remainder: [String]) -> AO3NewsRoute {
        guard let first = remainder.first else { return .main }
        if first == "comments" { return .comments }
        return .main
    }
}
