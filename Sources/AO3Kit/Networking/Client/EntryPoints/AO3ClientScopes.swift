//
//  AO3ClientScopes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

public extension AO3Client {
    /// Work metadata, chapters, comments, kudos, and work lists across users, collections, and tags.
    var works: WorksAPI { WorksAPI(client: self) }
    
    /// Full fic bookmarks across users, collections, tags, and series, plus work bookmark previews.
    var bookmarks: BookmarksAPI { BookmarksAPI(client: self) }
    
    /// Public user profiles, pseuds, and user series.
    var users: UsersAPI { UsersAPI(client: self) }
    
    /// Collection profiles and subcollections.
    var collections: CollectionsAPI { CollectionsAPI(client: self) }
    
    /// Series details and work lists.
    var series: SeriesAPI { SeriesAPI(client: self) }
    
    /// AO3 Admin Posts (news and announcements).
    var news: NewsAPI { NewsAPI(client: self) }
    
    /// Authenticated session management, inbox, reading history, subscriptions, stats, and muting/blocking.
    var account: AccountAPI { AccountAPI(client: self) }
}


/// Sources that return paginated lists of `AO3FicPreview`.
public enum AO3WorkSource: Sendable, Equatable {
    case userWorks(username: String)
    case userGifts(username: String)
    case collection(id: String)
    case tag(name: String)
    
    internal var endpoint: AO3Endpoint {
        switch self {
        case .userWorks(let username):
            return .user(username: username, route: .works)
        case .userGifts(let username):
            return .user(username: username, route: .gifts)
        case .collection(let id):
            return .collection(name: id, route: .works)
        case .tag(let name):
            return .tag(name: name, route: .works)
        }
    }
    
    public static func userWorks<Author: AO3AuthorModel>(_ author: Author) -> Self { .userWorks(username: author.username) }
    public static func userGifts<Author: AO3AuthorModel>(_ author: Author) -> Self { .userGifts(username: author.username) }
    public static func collection<Collection: AO3CollectionModel>(_ collection: Collection) -> Self { .collection(id: collection.id) }
}

/// Sources that return paginated lists of `AO3FicBookmark`.
public enum AO3BookmarkSource: Sendable, Equatable {
    case user(username: String)
    case collection(id: String)
    case tag(name: String)
    case series(id: Int)
    
    internal var endpoint: AO3Endpoint {
        switch self {
        case .user(let username):
            return .user(username: username, route: .bookmarks)
        case .collection(let id):
            return .collection(name: id, route: .bookmarks)
        case .tag(let name):
            return .tag(name: name, route: .bookmarks)
        case .series(let id):
            return .series(id: id, route: .bookmarks)
        }
    }
    
    public static func user<Author: AO3AuthorModel>(_ author: Author) -> Self { .user(username: author.username) }
    public static func collection<Collection: AO3CollectionModel>(_ collection: Collection) -> Self { .collection(id: collection.id) }
    public static func series<Series: AO3SeriesModel>(_ series: Series) -> Self { .series(id: series.id) }
}

/// Targets that hold comment threads (`AO3ChapterCommentThread`).
public enum AO3CommentTarget: Sendable, Equatable {
    case work(id: Int)
    case chapter(id: Int)
    
    internal var endpoint: AO3Endpoint {
        switch self {
        case .work(let id):
            return .work(id: id, route: .comments)
        case .chapter(let id):
            return .chapter(id: id, route: .comments)
        }
    }
    
    public static func work<Fic: AO3FicModel>(_ fic: Fic) -> Self { .work(id: fic.id) }
    public static func chapter(_ link: AO3ChapterLink) -> Self { .chapter(id: link.id) }
}

/// Account moderation lists returning `AO3MutedBlockedLink`.
public enum AO3ModerationListType: Sendable, Equatable {
    case muted
    case blocked
    
    internal func endpoint(for username: String) -> AO3Endpoint {
        switch self {
        case .muted:
            return .user(username: username, route: .muted)
        case .blocked:
            return .user(username: username, route: .blocked)
        }
    }
}
