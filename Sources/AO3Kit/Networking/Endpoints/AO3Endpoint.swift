//
//  AO3Endpoint.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

// MARK: - Generic Rails Resource Helper

public enum AO3ResourceAction<ID: Hashable & Sendable>: Equatable, Sendable {
    case index
    case new
    case show(id: ID)
    case edit(id: ID)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }

    static func dissect(remainder: [String], parseID: (String) -> ID?) -> AO3ResourceAction<ID>? {
        guard let first = remainder.first else { return .index }
        if first == "new" { return .new }
        guard let id = parseID(first) else { return nil }
        if remainder.count > 1, remainder[1] == "edit" {
            return .edit(id: id)
        }
        return .show(id: id)
    }
}

// MARK: - AO3Endpoint

public enum AO3Endpoint: Equatable, Sendable {
    // MARK: Core Member Domains
    case work(id: Int, route: AO3WorkRoute = .main)
    case user(username: String, route: AO3UserRoute = .profile)
    case collection(name: String, route: AO3CollectionRoute = .main)
    case tag(name: String, route: AO3TagRoute = .main)
    case series(id: Int, route: AO3SeriesRoute = .main)
    case chapter(id: Int, route: AO3ChapterRoute = .main)
    case commentThread(id: Int)

    // MARK: Root Collection / Global Resource Routes
    case worksCollection(AO3WorksCollectionRoute)
    case chaptersCollection(AO3SimpleCollectionRoute)
    case usersCollection(AO3UsersCollectionRoute)
    case collectionsIndex(AO3CollectionsIndexRoute)
    case tagsCollection(AO3TagsCollectionRoute)
    case seriesCollection(AO3SimpleCollectionRoute)
    case bookmarks(AO3BookmarkRoute)
    case comments(AO3CommentRoute)
    case people(AO3PeopleRoute)
    case kudos

    // MARK: Search & Autocomplete
    case worksSearch(queryItems: [URLQueryItem] = [])
    case tagsSearch(queryItems: [URLQueryItem] = [])
    case bookmarksSearch(queryItems: [URLQueryItem] = [])
    case peopleSearch(queryItems: [URLQueryItem] = [])
    case autocomplete(type: AO3AutocompleteType, queryItems: [URLQueryItem] = [])

    // MARK: Media, Fandoms, Wrangling & Tag Sets
    case media(AO3MediaRoute)
    case fandom(AO3FandomRoute)
    case tagWrangling(AO3TagWranglingRoute)
    case tagWrangler(AO3TagWranglerRoute)
    case unsortedTags(AO3UnsortedTagsRoute)
    case tagSet(AO3TagSetRoute)
    case tagNomination(id: Int)
    case tagWranglingRequests(AO3TagWranglingRequestsRoute)
    case wranglingGuidelines(AO3ManagedArticleRoute)

    // MARK: External, Related, Serial Works & Gifts
    case externalWork(AO3ExternalWorkRoute)
    case relatedWork(AO3ResourceAction<Int>)
    case serialWork(AO3ResourceAction<Int>)
    case externalAuthor(AO3ExternalAuthorRoute)
    case gift(AO3GiftRoute)
    case challenge(AO3ChallengeRoute)

    // MARK: Invitations, Claims & Orphans
    case invitation(AO3ResourceAction<String>)
    case userInviteRequest(AO3UserInviteRequestRoute)
    case inviteRequest(AO3InviteRequestRoute)
    case signup(invitationToken: String? = nil)
    case claim(invitationToken: String)
    case completeClaim(invitationToken: String)
    case activate(id: String)
    case orphan(AO3SimpleCollectionRoute)

    // MARK: Skins, Help, Info & Support
    case skin(AO3SkinRoute)
    case news(id: Int?, route: AO3NewsRoute = .main)
    case knownIssue(AO3ResourceAction<Int>)
    case faq(AO3FAQRoute)
    case help(page: String)
    case abuseReport(AO3AbuseReportRoute)
    case support
    case redirect(doRedirect: Bool = false)
    case menu(AO3MenuRoute)
    case staticPage(AO3StaticPage)
    case error(AO3ErrorRoute)

    // MARK: i18n, Downloads, OpenDoors, API & Admin
    case language(AO3LanguageRoute)
    case locale(AO3ResourceAction<String>)
    case download(workID: Int, title: String, format: String)
    case openDoors(AO3OpenDoorsRoute)
    case apiV2(AO3APIV2Route)
    case admin(AO3AdminRoute)
    case admins(AO3AdminsRoute)

    case home
    case unknown

    public static func autocomplete(type: String, queryItems: [URLQueryItem] = []) -> AO3Endpoint {
        .autocomplete(type: AO3AutocompleteType(rawValue: type), queryItems: queryItems)
    }

    // MARK: URL Builder
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

        case .worksCollection(let route):
            components.path = "/works" + route.pathSuffix
        case .chaptersCollection(let route):
            components.path = "/chapters" + route.pathSuffix
        case .usersCollection(let route):
            components.path = "/users" + route.pathSuffix
        case .collectionsIndex(let route):
            components.path = "/collections" + route.pathSuffix
        case .tagsCollection(let route):
            components.path = "/tags" + route.pathSuffix
        case .seriesCollection(let route):
            components.path = "/series" + route.pathSuffix
        case .bookmarks(let route):
            components.path = "/bookmarks" + route.pathSuffix
        case .comments(let route):
            components.path = "/comments" + route.pathSuffix
        case .people(let route):
            components.path = "/people" + route.pathSuffix
        case .kudos:
            components.path = "/kudos"

        case .worksSearch(let queryItems):
            components.path = "/works/search"
            routeQueryItems = queryItems
        case .tagsSearch(let queryItems):
            components.path = "/tags/search"
            routeQueryItems = queryItems
        case .bookmarksSearch(let queryItems):
            components.path = "/bookmarks/search"
            routeQueryItems = queryItems
        case .peopleSearch(let queryItems):
            components.path = "/people/search"
            routeQueryItems = queryItems
        case .autocomplete(let type, let queryItems):
            components.path = "/autocomplete/\(type.rawValue)"
            routeQueryItems = queryItems

        case .media(let route):
            components.path = "/media" + route.pathSuffix
        case .fandom(let route):
            components.path = "/fandoms" + route.pathSuffix
        case .tagWrangling(let route):
            components.path = "/tag_wranglings" + route.pathSuffix
        case .tagWrangler(let route):
            components.path = "/tag_wranglers" + route.pathSuffix
        case .unsortedTags(let route):
            components.path = "/unsorted_tags" + route.pathSuffix
        case .tagSet(let route):
            components.path = "/tag_sets" + route.pathSuffix
        case .tagNomination(let id):
            components.path = "/tag_nominations/\(id)"
        case .tagWranglingRequests(let route):
            components.path = "/tag_wrangling_requests" + route.pathSuffix
        case .wranglingGuidelines(let route):
            components.path = "/wrangling_guidelines" + route.pathSuffix

        case .externalWork(let route):
            components.path = "/external_works" + route.pathSuffix
        case .relatedWork(let action):
            components.path = "/related_works" + action.pathSuffix
        case .serialWork(let action):
            components.path = "/serial_works" + action.pathSuffix
        case .externalAuthor(let route):
            components.path = "/external_authors" + route.pathSuffix
        case .gift(let route):
            components.path = "/gifts" + route.pathSuffix
        case .challenge(let route):
            components.path = "/challenges" + route.pathSuffix

        case .invitation(let action):
            components.path = "/invitations" + action.pathSuffix
        case .userInviteRequest(let route):
            components.path = "/user_invite_requests" + route.pathSuffix
        case .inviteRequest(let route):
            components.path = "/invite_requests" + route.pathSuffix
        case .signup(let token):
            components.path = token.map { "/signup/\($0)" } ?? "/signup"
        case .claim(let token):
            components.path = "/claim/\(token)"
        case .completeClaim(let token):
            components.path = "/complete_claim/\(token)"
        case .activate(let id):
            components.path = "/activate/\(id)"
        case .orphan(let route):
            components.path = "/orphans" + route.pathSuffix

        case .skin(let route):
            components.path = "/skins" + route.pathSuffix
        case .news(let id, let route):
            if let id {
                components.path = "/admin_posts/\(id)" + route.pathSuffix
            } else {
                components.path = "/admin_posts" + route.newsCollectionSuffix
            }
            routeQueryItems = route.queryItems
        case .knownIssue(let action):
            components.path = "/known_issues" + action.pathSuffix
        case .faq(let route):
            components.path = "/faq" + route.pathSuffix
        case .help(let page):
            components.path = "/help/\(page)"
        case .abuseReport(let route):
            components.path = "/abuse_reports" + route.pathSuffix
        case .support:
            components.path = "/support"
        case .redirect(let doRedirect):
            components.path = doRedirect ? "/redirect/do_redirect" : "/redirect"
        case .menu(let route):
            components.path = "/menu/" + route.rawValue
        case .staticPage(let page):
            components.path = "/" + page.rawValue
        case .error(let route):
            components.path = "/" + route.rawValue

        case .language(let route):
            components.path = "/languages" + route.pathSuffix
        case .locale(let action):
            components.path = "/locales" + action.pathSuffix
        case .download(let workID, let title, let format):
            let safeTitle = title.replacingOccurrences(of: " ", with: "_")
            components.path = "/downloads/\(workID)/\(safeTitle).\(format)"
        case .openDoors(let route):
            components.path = "/opendoors" + route.pathSuffix
        case .apiV2(let route):
            components.path = "/api/v2" + route.pathSuffix
        case .admin(let route):
            components.path = "/admin" + route.pathSuffix
        case .admins(let route):
            components.path = "/admins" + route.pathSuffix

        case .home, .unknown:
            components.path = "/"
        }

        var allQueryItems = routeQueryItems
        if bypassAdultBlock {
            allQueryItems.append(URLQueryItem(name: "view_adult", value: "true"))
        }
        if let page, page > 1 {
            allQueryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        if !allQueryItems.isEmpty {
            components.queryItems = allQueryItems
        }

        return components.url
    }
}

// MARK: - Simple Collection Route (index / new)
public enum AO3SimpleCollectionRoute: Equatable, Sendable {
    case index
    case new

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        }
    }
}
