//
//  AO3ClientScopes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

public extension AO3Client {
    /// Work metadata, chapters, comments, kudos, and work lists across users, collections, and tags.
    var works: AO3WorksAPI { AO3WorksAPI(client: self) }
    
    /// Full fic bookmarks across users, collections, tags, and series, plus work bookmark previews.
    var bookmarks: AO3BookmarksAPI { AO3BookmarksAPI(client: self) }
    
    /// Public user profiles, pseuds, and user series.
    var users: AO3UsersAPI { AO3UsersAPI(client: self) }
    
    /// Collection profiles and subcollections.
    var collections: AO3CollectionsAPI { AO3CollectionsAPI(client: self) }
    
    /// Series details and work lists.
    var series: AO3SeriesAPI { AO3SeriesAPI(client: self) }
    
    /// AO3 Admin Posts (news and announcements).
    var news: AO3NewsAPI { AO3NewsAPI(client: self) }
    
    /// Authenticated session management, inbox, reading history, subscriptions, stats, and muting/blocking.
    var account: AO3AccountAPI { AO3AccountAPI(client: self) }
    
    /// AO3 Search Functionality
    var search: AO3SearchAPI { AO3SearchAPI(client: self) }

    /// Tag details and tag-scoped operations.
    var tags: AO3TagsAPI { AO3TagsAPI(client: self) }

    /// Media categories, fandom directories, and supported languages.
    var browse: AO3BrowseAPI { AO3BrowseAPI(client: self) }
    
    /// Fetching and caching image data for user avatars, collection icons, and embedded art.
    var images: AO3ImagesAPI { AO3ImagesAPI(client: self) }

    /// OTW / AO3 operational status and recent incident history.
    var status: AO3StatusMonitor { .shared }

    /// AO3 FAQ, known issues, static pages (ToS, Privacy, About), abuse reports, and support forms.
    var site: AO3SiteAPI { AO3SiteAPI(client: self) }
}


/// Sources that return paginated lists of `AO3FicPreview`.
public enum AO3WorkSource: Sendable, Equatable {
    case recent
    case userWorks(username: String, filter: AO3WorkSearchFilter? = nil)
    case pseudWorks(username: String, pseud: String, filter: AO3WorkSearchFilter? = nil)
    case userGifts(username: String)
    case collection(id: String, filter: AO3WorkSearchFilter? = nil)
    case collectionGifts(collectionID: String)
    case collectionTag(collectionID: String, tagName: String, filter: AO3WorkSearchFilter? = nil)
    case tag(name: String, filter: AO3WorkSearchFilter? = nil)
    case language(id: String)
    case search(filter: AO3WorkSearchFilter)
    
    internal var endpoint: AO3Endpoint {
        switch self {
        case .recent:
            return .worksCollection(.index)
        case .userWorks(let username, _):
            return .user(username: username, route: .works)
        case .pseudWorks(let username, let pseud, _):
            return .user(username: username, route: .pseudWorks(name: pseud, action: .index))
        case .userGifts(let username):
            return .user(username: username, route: .gifts)
        case .collection(let id, _):
            return .collection(name: id, route: .works)
        case .collectionGifts(let collectionID):
            return .collection(name: collectionID, route: .gifts(.index))
        case .collectionTag(let collectionID, let tagName, _):
            return .collection(name: collectionID, route: .tags(.works(tagName: tagName, action: .index)))
        case .tag(let name, _):
            return .tag(name: name, route: .works)
        case .language(let id):
            return .language(.works(languageID: id, action: .index))
        case .search(let filter):
            return .worksSearch(queryItems: filter.queryItems)
        }
    }

    internal var filterQueryItems: [URLQueryItem] {
        switch self {
        case .userWorks(_, let filter),
             .pseudWorks(_, _, let filter),
             .collection(_, let filter),
             .collectionTag(_, _, let filter),
             .tag(_, let filter):
            return filter?.queryItems ?? []
        default:
            return []
        }
    }

    internal func url(bypassAdultBlock: Bool) -> URL? {
        guard let baseURL = endpoint.url(bypassAdultBlock: bypassAdultBlock) else { return nil }
        let extraItems = filterQueryItems
        guard !extraItems.isEmpty,
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }
        var items = components.queryItems ?? []
        items.append(contentsOf: extraItems)
        components.queryItems = items
        return components.url
    }
    
    public static func userWorks<Author: AO3AuthorModel>(_ author: Author, filter: AO3WorkSearchFilter? = nil) -> Self {
        .userWorks(username: author.username, filter: filter)
    }
    public static func pseudWorks(_ pseud: AO3AuthorPseudLink, filter: AO3WorkSearchFilter? = nil) -> Self {
        .pseudWorks(username: pseud.username, pseud: pseud.pseudName, filter: filter)
    }
    public static func userGifts<Author: AO3AuthorModel>(_ author: Author) -> Self { .userGifts(username: author.username) }
    public static func collection<Collection: AO3CollectionModel>(_ collection: Collection, filter: AO3WorkSearchFilter? = nil) -> Self {
        .collection(id: collection.id, filter: filter)
    }
    public static func collectionGifts<Collection: AO3CollectionModel>(_ collection: Collection) -> Self {
        .collectionGifts(collectionID: collection.id)
    }
    public static func collectionTag<Collection: AO3CollectionModel, Tag: AO3TagModel>(
        _ collection: Collection,
        tag: Tag,
        filter: AO3WorkSearchFilter? = nil
    ) -> Self {
        .collectionTag(collectionID: collection.id, tagName: tag.tagName, filter: filter)
    }
    public static func tag<Tag: AO3TagModel>(_ tag: Tag, filter: AO3WorkSearchFilter? = nil) -> Self {
        .tag(name: tag.tagName, filter: filter)
    }
    public static func language(_ language: AO3Language) -> Self { .language(id: language.id) }
}

/// Sources that return paginated lists of `AO3FicBookmark`.
public enum AO3BookmarkSource: Sendable, Equatable {
    case recent
    case user(username: String, filter: AO3BookmarkSearchFilter? = nil)
    case pseud(username: String, pseud: String, filter: AO3BookmarkSearchFilter? = nil)
    case collection(id: String, filter: AO3BookmarkSearchFilter? = nil)
    case tag(name: String, filter: AO3BookmarkSearchFilter? = nil)
    case series(id: Int)
    case externalWork(id: Int)
    case search(filter: AO3BookmarkSearchFilter)
    
    internal var endpoint: AO3Endpoint {
        switch self {
        case .recent:
            return .bookmarks(.index)
        case .user(let username, _):
            return .user(username: username, route: .bookmarks)
        case .pseud(let username, let pseud, _):
            return .user(username: username, route: .pseudBookmarks(name: pseud, action: .index))
        case .collection(let id, _):
            return .collection(name: id, route: .bookmarks)
        case .tag(let name, _):
            return .tag(name: name, route: .bookmarks)
        case .series(let id):
            return .series(id: id, route: .bookmarks)
        case .externalWork(let id):
            return .externalWork(.bookmarks(externalWorkID: id, action: .index))
        case .search(let filter):
            return .bookmarksSearch(queryItems: filter.queryItems)
        }
    }

    internal var filterQueryItems: [URLQueryItem] {
        switch self {
        case .user(_, let filter),
             .pseud(_, _, let filter),
             .collection(_, let filter),
             .tag(_, let filter):
            return filter?.queryItems ?? []
        default:
            return []
        }
    }

    internal func url(bypassAdultBlock: Bool) -> URL? {
        guard let baseURL = endpoint.url(bypassAdultBlock: bypassAdultBlock) else { return nil }
        let extraItems = filterQueryItems
        guard !extraItems.isEmpty,
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }
        var items = components.queryItems ?? []
        items.append(contentsOf: extraItems)
        components.queryItems = items
        return components.url
    }
    
    public static func user<Author: AO3AuthorModel>(_ author: Author, filter: AO3BookmarkSearchFilter? = nil) -> Self {
        .user(username: author.username, filter: filter)
    }
    public static func pseud(_ pseud: AO3AuthorPseudLink, filter: AO3BookmarkSearchFilter? = nil) -> Self {
        .pseud(username: pseud.username, pseud: pseud.pseudName, filter: filter)
    }
    public static func collection<Collection: AO3CollectionModel>(_ collection: Collection, filter: AO3BookmarkSearchFilter? = nil) -> Self {
        .collection(id: collection.id, filter: filter)
    }
    public static func series<Series: AO3SeriesModel>(_ series: Series) -> Self { .series(id: series.id) }
    public static func tag<Tag: AO3TagModel>(_ tag: Tag, filter: AO3BookmarkSearchFilter? = nil) -> Self {
        .tag(name: tag.tagName, filter: filter)
    }
}

/// Targets that hold comment threads (`AO3ChapterCommentThread`).
public enum AO3CommentTarget: Sendable, Equatable {
    case work(id: Int)
    case chapter(id: Int)
    case adminPost(id: Int)
    
    internal var endpoint: AO3Endpoint {
        switch self {
        case .work(let id):
            return .work(id: id, route: .comments)
        case .chapter(let id):
            return .chapter(id: id, route: .comments)
        case .adminPost(let id):
            return .news(id: id, route: .comments)
        }
    }
    
    public static func work<Fic: AO3FicModel>(_ fic: Fic) -> Self { .work(id: fic.id) }
    public static func chapter(_ link: AO3ChapterLink) -> Self { .chapter(id: link.id) }
    public static func adminPost(_ post: AO3AdminPost) -> Self { .adminPost(id: post.id) }
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
