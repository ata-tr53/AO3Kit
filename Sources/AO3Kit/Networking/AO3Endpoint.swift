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
    case feedback(isPost: Bool = false) // /support
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
        case .feedback:
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

// MARK: - User Routes
public enum AO3UsersCollectionRoute: Equatable, Sendable {
    case index
    case login
    case logout
    case signUp
    case editRegistration
    case cancelRegistration
    case password(AO3DevisePasswordRoute)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .login: return "/login"
        case .logout: return "/logout"
        case .signUp: return "/sign_up"
        case .editRegistration: return "/edit"
        case .cancelRegistration: return "/cancel"
        case .password(let route): return "/password" + route.pathSuffix
        }
    }
}

public enum AO3DevisePasswordRoute: Equatable, Sendable {
    case root
    case new
    case edit
    case reset

    public var pathSuffix: String {
        switch self {
        case .root: return ""
        case .new: return "/new"
        case .edit: return "/edit"
        case .reset: return "/reset"
        }
    }
}

public enum AO3UserRoute: Equatable, Sendable {
    case dashboard // /users/:username
    case profile   // /users/:username/profile
    case editProfile
    case profilePseuds

    // Member account actions
    case changeEmail
    case confirmChangeEmail
    case changedEmail
    case changePassword
    case changedPassword
    case changeUsername
    case changedUsername
    case endFirstLogin
    case endBanner
    case endTosPrompt
    case reconfirmEmail

    // Works & Series
    case works
    case worksSub(AO3UserWorksRoute)
    case series
    case seriesSub(AO3UserSeriesRoute)
    case bookmarks(AO3ResourceAction<Int> = .index)
    case gifts
    case subscriptions
    case deleteSubscription(id: Int)
    case confirmDeleteAllSubscriptions
    case deleteAllSubscriptions

    // Pseuds
    case allPseuds
    case pseud(name: String)
    case newPseud
    case editPseud(name: String)
    case pseudWorks(name: String, action: AO3ResourceAction<Int>)
    case pseudSeries(name: String, action: AO3ResourceAction<Int>)
    case pseudBookmarks(name: String, action: AO3ResourceAction<Int>)

    // Moderation & History
    case muted
    case confirmMute(targetUsername: String? = nil)
    case muteItem(id: Int)
    case confirmUnmute(id: Int)
    case blocked
    case confirmBlock(targetUsername: String? = nil)
    case blockItem(id: Int)
    case confirmUnblock(id: Int)
    case favoriteTags
    case deleteFavoriteTag(id: Int)
    case history(showToRead: Bool = false)
    case newHistoryItem
    case historyItem(id: Int)
    case editHistoryItem(id: Int)
    case clearHistory
    case clearHistoryAction

    // Other Nested User Resources
    case inbox
    case inboxAction(AO3UserInboxRoute)
    case stats
    case preferences(id: Int? = nil)
    case skins
    case tagSets
    case nominations
    case assignments
    case claims
    case signups
    case collections
    case collectionItems(AO3UserCollectionItemsRoute)
    case comments(AO3UserCommentsRoute)
    case creatorships
    case relatedWorks(AO3ResourceAction<Int>)
    case externalAuthors(AO3ExternalAuthorRoute)
    case invitations(AO3UserInvitationsRoute)

    public var pathSuffix: String {
        switch self {
        case .dashboard: return ""
        case .profile: return "/profile"
        case .editProfile: return "/profile/edit"
        case .profilePseuds: return "/profile/pseuds"

        case .changeEmail: return "/change_email"
        case .confirmChangeEmail: return "/confirm_change_email"
        case .changedEmail: return "/changed_email"
        case .changePassword: return "/change_password"
        case .changedPassword: return "/changed_password"
        case .changeUsername: return "/change_username"
        case .changedUsername: return "/changed_username"
        case .endFirstLogin: return "/end_first_login"
        case .endBanner: return "/end_banner"
        case .endTosPrompt: return "/end_tos_prompt"
        case .reconfirmEmail: return "/reconfirm_email"

        case .works: return "/works"
        case .worksSub(let route): return "/works" + route.pathSuffix
        case .series: return "/series"
        case .seriesSub(let route): return "/series" + route.pathSuffix
        case .bookmarks(let action): return "/bookmarks" + action.pathSuffix
        case .gifts: return "/gifts"
        case .subscriptions: return "/subscriptions"
        case .deleteSubscription(let id): return "/subscriptions/\(id)"
        case .confirmDeleteAllSubscriptions: return "/subscriptions/confirm_delete_all"
        case .deleteAllSubscriptions: return "/subscriptions/delete_all"

        case .allPseuds: return "/pseuds"
        case .newPseud: return "/pseuds/new"
        case .pseud(let name): return "/pseuds/\(name)"
        case .editPseud(let name): return "/pseuds/\(name)/edit"
        case .pseudWorks(let name, let action): return "/pseuds/\(name)/works" + action.pathSuffix
        case .pseudSeries(let name, let action): return "/pseuds/\(name)/series" + action.pathSuffix
        case .pseudBookmarks(let name, let action): return "/pseuds/\(name)/bookmarks" + action.pathSuffix

        case .muted: return "/muted/users"
        case .confirmMute: return "/muted/users/confirm_mute"
        case .muteItem(let id): return "/muted/users/\(id)"
        case .confirmUnmute(let id): return "/muted/users/\(id)/confirm_unmute"
        case .blocked: return "/blocked/users"
        case .confirmBlock: return "/blocked/users/confirm_block"
        case .blockItem(let id): return "/blocked/users/\(id)"
        case .confirmUnblock(let id): return "/blocked/users/\(id)/confirm_unblock"
        case .favoriteTags: return "/favorite_tags"
        case .deleteFavoriteTag(let id): return "/favorite_tags/\(id)"
        case .history: return "/readings"
        case .newHistoryItem: return "/readings/new"
        case .historyItem(let id): return "/readings/\(id)"
        case .editHistoryItem(let id): return "/readings/\(id)/edit"
        case .clearHistory: return "/readings/confirm_clear"
        case .clearHistoryAction: return "/readings/clear"

        case .inbox: return "/inbox"
        case .inboxAction(let route): return "/inbox" + route.pathSuffix
        case .stats: return "/stats"
        case .preferences(let id): return id.map { "/preferences/\($0)" } ?? "/preferences"
        case .skins: return "/skins"
        case .tagSets: return "/tag_sets"
        case .nominations: return "/nominations"
        case .assignments: return "/assignments"
        case .claims: return "/claims"
        case .signups: return "/signups"
        case .collections: return "/collections"
        case .collectionItems(let route): return "/collection_items" + route.pathSuffix
        case .comments(let route): return "/comments" + route.pathSuffix
        case .creatorships: return "/creatorships"
        case .relatedWorks(let action): return "/related_works" + action.pathSuffix
        case .externalAuthors(let route): return "/external_authors" + route.pathSuffix
        case .invitations(let route): return "/invitations" + route.pathSuffix
        }
    }

    public var queryItems: [URLQueryItem] {
        switch self {
        case .history(let showToRead):
            return showToRead ? [URLQueryItem(name: "show", value: "to-read")] : []
        case .confirmMute(let target):
            return target.map { [URLQueryItem(name: "muted_id", value: $0)] } ?? []
        case .confirmBlock(let target):
            return target.map { [URLQueryItem(name: "blocked_id", value: $0)] } ?? []
        default:
            return []
        }
    }

    static func dissect(remainder: [String], queryItems: [URLQueryItem]? = nil) -> AO3UserRoute {
        guard let first = remainder.first else { return .dashboard }
        let rest = Array(remainder.dropFirst())

        switch first {
        case "profile":
            switch rest.first {
            case "edit": return .editProfile
            case "pseuds": return .profilePseuds
            default: return .profile
            }
        case "change_email": return .changeEmail
        case "confirm_change_email": return .confirmChangeEmail
        case "changed_email": return .changedEmail
        case "change_password": return .changePassword
        case "changed_password": return .changedPassword
        case "change_username": return .changeUsername
        case "changed_username": return .changedUsername
        case "end_first_login": return .endFirstLogin
        case "end_banner": return .endBanner
        case "end_tos_prompt": return .endTosPrompt
        case "reconfirm_email": return .reconfirmEmail
        case "gifts": return .gifts
        case "stats": return .stats
        case "preferences": return .preferences(id: rest.first.flatMap(Int.init))
        case "skins": return .skins
        case "tag_sets": return .tagSets
        case "nominations": return .nominations
        case "assignments": return .assignments
        case "claims": return .claims
        case "signups": return .signups
        case "collections": return .collections
        case "creatorships": return .creatorships

        case "works":
            guard let sub = rest.first else { return .works }
            switch sub {
            case "drafts": return .worksSub(.drafts)
            case "collected": return .worksSub(.collected)
            case "show_multiple": return .worksSub(.showMultiple)
            case "edit_multiple": return .worksSub(.editMultiple)
            case "update_multiple": return .worksSub(.updateMultiple)
            case "delete_multiple": return .worksSub(.deleteMultiple)
            case "new": return .worksSub(.new)
            default:
                if let id = Int(sub) {
                    return .worksSub(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))
                }
                return .works
            }

        case "series":
            guard let sub = rest.first else { return .series }
            if sub == "new" { return .seriesSub(.new) }
            if let id = Int(sub) {
                let sRest = Array(rest.dropFirst())
                switch sRest.first {
                case "edit": return .seriesSub(.edit(id: id))
                case "manage": return .seriesSub(.manage(id: id))
                case "serial_works":
                    let action = AO3ResourceAction.dissect(remainder: Array(sRest.dropFirst()), parseID: Int.init) ?? .index
                    return .seriesSub(.serialWorks(seriesID: id, action: action))
                default: return .seriesSub(.show(id: id))
                }
            }
            return .series

        case "bookmarks":
            return .bookmarks(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)

        case "subscriptions":
            switch rest.first {
            case "confirm_delete_all": return .confirmDeleteAllSubscriptions
            case "delete_all": return .deleteAllSubscriptions
            case let s? where Int(s) != nil: return .deleteSubscription(id: Int(s)!)
            default: return .subscriptions
            }

        case "readings":
            switch rest.first {
            case "clear": return .clearHistoryAction
            case "confirm_clear": return .clearHistory
            case "new": return .newHistoryItem
            case let s? where Int(s) != nil:
                let id = Int(s)!
                return rest.dropFirst().first == "edit" ? .editHistoryItem(id: id) : .historyItem(id: id)
            default:
                let isToRead = queryItems?.contains { $0.name == "show" && $0.value == "to-read" } ?? false
                return .history(showToRead: isToRead)
            }

        case "pseuds":
            guard let rawName = rest.first else { return .allPseuds }
            if rawName == "new" { return .newPseud }
            let name = rawName.removingPercentEncoding ?? rawName
            let pRest = Array(rest.dropFirst())
            switch pRest.first {
            case "edit": return .editPseud(name: name)
            case "works": return .pseudWorks(name: name, action: AO3ResourceAction.dissect(remainder: Array(pRest.dropFirst()), parseID: Int.init) ?? .index)
            case "series": return .pseudSeries(name: name, action: AO3ResourceAction.dissect(remainder: Array(pRest.dropFirst()), parseID: Int.init) ?? .index)
            case "bookmarks": return .pseudBookmarks(name: name, action: AO3ResourceAction.dissect(remainder: Array(pRest.dropFirst()), parseID: Int.init) ?? .index)
            default: return .pseud(name: name)
            }

        case "favorite_tags":
            if let idStr = rest.first, let id = Int(idStr) { return .deleteFavoriteTag(id: id) }
            return .favoriteTags

        case "muted":
            let mRest = rest.first == "users" ? Array(rest.dropFirst()) : rest
            if mRest.first == "confirm_mute" {
                let target = queryItems?.first(where: { $0.name == "muted_id" })?.value
                return .confirmMute(targetUsername: target)
            }
            if let idStr = mRest.first, let id = Int(idStr) {
                return mRest.dropFirst().first == "confirm_unmute" ? .confirmUnmute(id: id) : .muteItem(id: id)
            }
            return .muted

        case "blocked":
            let bRest = rest.first == "users" ? Array(rest.dropFirst()) : rest
            if bRest.first == "confirm_block" {
                let target = queryItems?.first(where: { $0.name == "blocked_id" })?.value
                return .confirmBlock(targetUsername: target)
            }
            if let idStr = bRest.first, let id = Int(idStr) {
                return bRest.dropFirst().first == "confirm_unblock" ? .confirmUnblock(id: id) : .blockItem(id: id)
            }
            return .blocked

        case "inbox":
            switch rest.first {
            case "new": return .inboxAction(.new)
            case "edit": return .inboxAction(.edit)
            case "reply": return .inboxAction(.reply)
            case "delete": return .inboxAction(.delete)
            default: return .inbox
            }

        case "collection_items":
            if rest.first == "update_multiple" { return .collectionItems(.updateMultiple) }
            if let idStr = rest.first, let id = Int(idStr) { return .collectionItems(.item(id: id)) }
            return .collectionItems(.index)

        case "comments":
            guard let sub = rest.first else { return .comments(.index) }
            if sub == "new" { return .comments(.new) }
            if let id = Int(sub) {
                switch rest.dropFirst().first {
                case "edit": return .comments(.edit(id: id))
                case "approve": return .comments(.approve(id: id))
                case "reject": return .comments(.reject(id: id))
                default: return .comments(.show(id: id))
                }
            }
            return .comments(.index)

        case "related_works":
            return .relatedWorks(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)

        case "external_authors":
            return .externalAuthors(AO3ExternalAuthorRoute.dissect(remainder: rest))

        case "invitations":
            switch rest.first {
            case nil: return .invitations(.index)
            case "new": return .invitations(.new)
            case "manage": return .invitations(.manage)
            case "invite_friend": return .invitations(.inviteFriend)
            case let id?:
                return .invitations(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))
            }

        default:
            return .dashboard
        }
    }
}

public extension AO3UserRoute {
    static var bookmarks: AO3UserRoute { .bookmarks(.index) }
    static var preferences: AO3UserRoute { .preferences(id: nil) }
}

public enum AO3UserWorksRoute: Equatable, Sendable {
    case drafts
    case collected
    case showMultiple
    case editMultiple
    case updateMultiple
    case deleteMultiple
    case new
    case show(id: Int)
    case edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .drafts: return "/drafts"
        case .collected: return "/collected"
        case .showMultiple: return "/show_multiple"
        case .editMultiple: return "/edit_multiple"
        case .updateMultiple: return "/update_multiple"
        case .deleteMultiple: return "/delete_multiple"
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3UserSeriesRoute: Equatable, Sendable {
    case new
    case show(id: Int)
    case edit(id: Int)
    case manage(id: Int)
    case serialWorks(seriesID: Int, action: AO3ResourceAction<Int>)

    public var pathSuffix: String {
        switch self {
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .manage(let id): return "/\(id)/manage"
        case .serialWorks(let sid, let action): return "/\(sid)/serial_works" + action.pathSuffix
        }
    }
}

public enum AO3UserInboxRoute: Equatable, Sendable {
    case new
    case edit
    case reply
    case delete

    public var pathSuffix: String {
        switch self {
        case .new: return "/new"
        case .edit: return "/edit"
        case .reply: return "/reply"
        case .delete: return "/delete"
        }
    }
}

public enum AO3UserCollectionItemsRoute: Equatable, Sendable {
    case index
    case updateMultiple
    case item(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .updateMultiple: return "/update_multiple"
        case .item(let id): return "/\(id)"
        }
    }
}

public enum AO3UserCommentsRoute: Equatable, Sendable {
    case index
    case new
    case show(id: Int)
    case edit(id: Int)
    case approve(id: Int)
    case reject(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .approve(let id): return "/\(id)/approve"
        case .reject(let id): return "/\(id)/reject"
        }
    }
}

public enum AO3UserInvitationsRoute: Equatable, Sendable {
    case index
    case new
    case manage
    case inviteFriend
    case show(id: String)
    case edit(id: String)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .manage: return "/manage"
        case .inviteFriend: return "/invite_friend"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

// MARK: - Collection Routes
public enum AO3CollectionsIndexRoute: Equatable, Sendable {
    case index
    case new
    case listChallenges
    case listGEChallenges
    case listPMChallenges

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .listChallenges: return "/list_challenges"
        case .listGEChallenges: return "/list_ge_challenges"
        case .listPMChallenges: return "/list_pm_challenges"
        }
    }
}

public enum AO3CollectionRoute: Equatable, Sendable {
    case main
    case edit
    case confirmDelete
    case profile
    case profileAction(AO3CollectionSingletonRoute)
    case works(AO3ResourceAction<Int> = .index)
    case bookmarks(AO3ResourceAction<Int> = .index)
    case tags(AO3CollectionTagsRoute = .index)
    case fandoms(AO3ResourceAction<String> = .index)
    case media(AO3ResourceAction<String> = .index)
    case people(AO3ResourceAction<String> = .index)
    case collections(AO3ResourceAction<String> = .index)
    case gifts(AO3ResourceAction<Int> = .index)
    case prompts(AO3CollectionPromptRoute)
    case participants(AO3CollectionParticipantsRoute)
    case items(AO3CollectionItemsRoute)
    case signups(AO3CollectionSignupsRoute)
    case assignments(AO3CollectionAssignmentsRoute)
    case claims(AO3CollectionClaimsRoute)
    case potentialMatches(AO3CollectionPotentialMatchesRoute)
    case requests(AO3ResourceAction<Int>)
    case giftExchange(AO3CollectionSingletonRoute)
    case promptMeme(AO3CollectionSingletonRoute)

    public var pathSuffix: String {
        switch self {
        case .main: return ""
        case .edit: return "/edit"
        case .confirmDelete: return "/confirm_delete"
        case .profile: return "/profile"
        case .profileAction(let sub): return "/profile" + sub.pathSuffix
        case .works(let action): return "/works" + action.pathSuffix
        case .bookmarks(let action): return "/bookmarks" + action.pathSuffix
        case .tags(let route): return "/tags" + route.pathSuffix
        case .fandoms(let action): return "/fandoms" + action.pathSuffix
        case .media(let action): return "/media" + action.pathSuffix
        case .people(let action): return "/people" + action.pathSuffix
        case .collections(let action): return "/collections" + action.pathSuffix
        case .gifts(let action): return "/gifts" + action.pathSuffix
        case .prompts(let route): return "/prompts" + route.pathSuffix
        case .participants(let route): return "/participants" + route.pathSuffix
        case .items(let route): return "/items" + route.pathSuffix
        case .signups(let route): return "/signups" + route.pathSuffix
        case .assignments(let route): return "/assignments" + route.pathSuffix
        case .claims(let route): return "/claims" + route.pathSuffix
        case .potentialMatches(let route): return "/potential_matches" + route.pathSuffix
        case .requests(let action): return "/requests" + action.pathSuffix
        case .giftExchange(let sub): return "/gift_exchange" + sub.pathSuffix
        case .promptMeme(let sub): return "/prompt_meme" + sub.pathSuffix
        }
    }

    public var queryItems: [URLQueryItem] { [] }

    static func dissect(remainder: [String]) -> AO3CollectionRoute {
        guard let first = remainder.first else { return .main }
        let rest = Array(remainder.dropFirst())

        switch first {
        case "edit": return .edit
        case "confirm_delete": return .confirmDelete
        case "profile":
            switch rest.first {
            case "new": return .profileAction(.new)
            case "edit": return .profileAction(.edit)
            case "confirm_delete": return .profileAction(.confirmDelete)
            default: return .profile
            }
        case "works": return .works(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        case "bookmarks": return .bookmarks(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        case "gifts": return .gifts(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        case "media": return .media(AO3ResourceAction.dissect(remainder: rest, parseID: { $0 }) ?? .index)
        case "fandoms": return .fandoms(AO3ResourceAction.dissect(remainder: rest, parseID: { $0 }) ?? .index)
        case "people": return .people(AO3ResourceAction.dissect(remainder: rest, parseID: { $0 }) ?? .index)
        case "collections": return .collections(AO3ResourceAction.dissect(remainder: rest, parseID: { $0 }) ?? .index)
        case "requests": return .requests(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index)
        case "tags":
            guard let t = rest.first else { return .tags(.index) }
            if t == "new" { return .tags(.new) }
            let decoded = (t.removingPercentEncoding ?? t).ao3TagDecoded
            let tRest = Array(rest.dropFirst())
            switch tRest.first {
            case "edit": return .tags(.edit(name: decoded))
            case "works":
                let action = AO3ResourceAction.dissect(remainder: Array(tRest.dropFirst()), parseID: Int.init) ?? .index
                return .tags(.works(tagName: decoded, action: action))
            default: return .tags(.show(name: decoded))
            }
        case "prompts":
            if rest.first == "new" { return .prompts(.new) }
            if let idStr = rest.first, let id = Int(idStr) {
                return .prompts(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))
            }
            return .main
        case "participants":
            switch rest.first {
            case "add": return .participants(.add)
            case "join": return .participants(.join)
            case let s? where Int(s) != nil: return .participants(.item(id: Int(s)!))
            default: return .participants(.index)
            }
        case "items":
            switch rest.first {
            case "new": return .items(.new)
            case "update_multiple": return .items(.updateMultiple)
            case let s? where Int(s) != nil:
                let id = Int(s)!
                return .items(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))
            default: return .items(.index)
            }
        case "signups":
            switch rest.first {
            case "new": return .signups(.new)
            case "summary": return .signups(.summary)
            case let s? where Int(s) != nil:
                let id = Int(s)!
                switch rest.dropFirst().first {
                case "edit": return .signups(.edit(id: id))
                case "confirm_delete": return .signups(.confirmDelete(id: id))
                default: return .signups(.show(id: id))
                }
            default: return .signups(.index)
            }
        case "assignments":
            switch rest.first {
            case "confirm_purge": return .assignments(.confirmPurge)
            case "generate": return .assignments(.generate)
            case "set": return .assignments(.set)
            case "purge": return .assignments(.purge)
            case "send_out": return .assignments(.sendOut)
            case "update_multiple": return .assignments(.updateMultiple)
            case "default_all": return .assignments(.defaultAll)
            case let s? where Int(s) != nil:
                let id = Int(s)!
                return .assignments(rest.dropFirst().first == "default" ? .default(id: id) : .show(id: id))
            default: return .assignments(.index)
            }
        case "claims":
            switch rest.first {
            case "new": return .claims(.new)
            case "set": return .claims(.set)
            case "purge": return .claims(.purge)
            case let s? where Int(s) != nil:
                let id = Int(s)!
                return .claims(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))
            default: return .claims(.index)
            }
        case "potential_matches":
            switch rest.first {
            case "new": return .potentialMatches(.new)
            case "generate": return .potentialMatches(.generate)
            case "cancel_generate": return .potentialMatches(.cancelGenerate)
            case "regenerate_for_signup": return .potentialMatches(.regenerateForSignup)
            case let s? where Int(s) != nil:
                let id = Int(s)!
                return .potentialMatches(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))
            default: return .potentialMatches(.index)
            }
        case "gift_exchange":
            switch rest.first {
            case "new": return .giftExchange(.new)
            case "edit": return .giftExchange(.edit)
            case "confirm_delete": return .giftExchange(.confirmDelete)
            default: return .giftExchange(.show)
            }
        case "prompt_meme":
            switch rest.first {
            case "new": return .promptMeme(.new)
            case "edit": return .promptMeme(.edit)
            case "confirm_delete": return .promptMeme(.confirmDelete)
            default: return .promptMeme(.show)
            }
        default:
            return .main
        }
    }
}

public extension AO3CollectionRoute {
    static var works: AO3CollectionRoute { .works(.index) }
    static var bookmarks: AO3CollectionRoute { .bookmarks(.index) }
    static var tags: AO3CollectionRoute { .tags(.index) }
    static var fandoms: AO3CollectionRoute { .fandoms(.index) }
    static var media: AO3CollectionRoute { .media(.index) }
    static var people: AO3CollectionRoute { .people(.index) }
    static var collections: AO3CollectionRoute { .collections(.index) }
}

public enum AO3CollectionSingletonRoute: Equatable, Sendable {
    case show, new, edit, confirmDelete
    public var pathSuffix: String {
        switch self {
        case .show: return ""
        case .new: return "/new"
        case .edit: return "/edit"
        case .confirmDelete: return "/confirm_delete"
        }
    }
}

public enum AO3CollectionTagsRoute: Equatable, Sendable {
    case index, new
    case show(name: String)
    case edit(name: String)
    case works(tagName: String, action: AO3ResourceAction<Int>)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let name): return "/\(name.ao3TagEncoded)"
        case .edit(let name): return "/\(name.ao3TagEncoded)/edit"
        case .works(let name, let action): return "/\(name.ao3TagEncoded)/works" + action.pathSuffix
        }
    }
}

public enum AO3CollectionPromptRoute: Equatable, Sendable {
    case new
    case show(id: Int)
    case edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3CollectionParticipantsRoute: Equatable, Sendable {
    case index, add, join
    case item(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .add: return "/add"
        case .join: return "/join"
        case .item(let id): return "/\(id)"
        }
    }
}

public enum AO3CollectionItemsRoute: Equatable, Sendable {
    case index, new, updateMultiple
    case show(id: Int)
    case edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .updateMultiple: return "/update_multiple"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3CollectionSignupsRoute: Equatable, Sendable {
    case index, new, summary
    case show(id: Int)
    case edit(id: Int)
    case confirmDelete(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .summary: return "/summary"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        }
    }
}

public enum AO3CollectionAssignmentsRoute: Equatable, Sendable {
    case index, confirmPurge, generate, set, purge, sendOut, updateMultiple, defaultAll
    case show(id: Int)
    case `default`(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .confirmPurge: return "/confirm_purge"
        case .generate: return "/generate"
        case .set: return "/set"
        case .purge: return "/purge"
        case .sendOut: return "/send_out"
        case .updateMultiple: return "/update_multiple"
        case .defaultAll: return "/default_all"
        case .show(let id): return "/\(id)"
        case .default(let id): return "/\(id)/default"
        }
    }
}

public enum AO3CollectionClaimsRoute: Equatable, Sendable {
    case index, new, set, purge
    case show(id: Int)
    case edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .set: return "/set"
        case .purge: return "/purge"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3CollectionPotentialMatchesRoute: Equatable, Sendable {
    case index, new, generate, cancelGenerate, regenerateForSignup
    case show(id: Int)
    case edit(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .generate: return "/generate"
        case .cancelGenerate: return "/cancel_generate"
        case .regenerateForSignup: return "/regenerate_for_signup"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

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

// MARK: - Skins, FAQ, Abuse, Languages, Menus, Static, Errors
public enum AO3SkinRoute: Equatable, Sendable {
    case index, new, unset
    case show(id: Int), edit(id: Int), preview(id: Int), set(id: Int), confirmDelete(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .unset: return "/unset"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .preview(let id): return "/\(id)/preview"
        case .set(let id): return "/\(id)/set"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        }
    }
}

public enum AO3FAQRoute: Equatable, Sendable {
    case index, new, manage, updatePositions
    case show(id: String), edit(id: String), confirmDelete(id: String)
    case questions(faqID: String, route: AO3ManagedArticleRoute)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .manage: return "/manage"
        case .updatePositions: return "/update_positions"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        case .questions(let fid, let route): return "/\(fid)/questions" + route.pathSuffix
        }
    }
}

public enum AO3AbuseReportRoute: Equatable, Sendable {
    case create, new
    public var pathSuffix: String { self == .new ? "/new" : "" }
}

public enum AO3LanguageRoute: Equatable, Sendable {
    case index, new
    case show(id: String), edit(id: String)
    case works(languageID: String, action: AO3ResourceAction<Int>)
    case adminPosts(languageID: String, action: AO3ResourceAction<Int>)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .works(let lid, let action): return "/\(lid)/works" + action.pathSuffix
        case .adminPosts(let lid, let action): return "/\(lid)/admin_posts" + action.pathSuffix
        }
    }
}

public enum AO3MenuRoute: String, Equatable, Sendable {
    case browse, fandoms, search, about
}

public enum AO3StaticPage: String, Equatable, Sendable {
    case search
    case content
    case privacy
    case tos
    case tosFaq = "tos_faq"
    case unicornTest = "unicorn_test"
    case dmca
    case takedown
    case diversity
    case siteMap = "site_map"
    case sitePages = "site_pages"
    case tokenDispenser = "token_dispenser"
    case deleteConfirmation = "delete_confirmation"
    case devmode
    case donate
    case lostCookie = "lost_cookie"
    case about
    case firstLoginHelp = "first_login_help"
}

public enum AO3ErrorRoute: String, Equatable, Sendable {
    case forbidden = "403"
    case notFound = "404"
    case unprocessable = "422"
    case rateLimited = "429"
    case serverError = "500"
    case authError = "auth_error"
    case timeoutError = "timeout_error"
}

// MARK: - OpenDoors, API v2, Admin
public enum AO3OpenDoorsRoute: Equatable, Sendable {
    case tools
    case toolsURLUpdate
    case externalAuthors(AO3OpenDoorsAuthorRoute)

    public var pathSuffix: String {
        switch self {
        case .tools: return "/tools"
        case .toolsURLUpdate: return "/tools/url_update"
        case .externalAuthors(let sub): return "/external_authors" + sub.pathSuffix
        }
    }
}

public enum AO3OpenDoorsAuthorRoute: Equatable, Sendable {
    case index, new
    case show(id: Int), edit(id: Int), forward(id: Int)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .forward(let id): return "/\(id)/forward"
        }
    }
}

public enum AO3APIV2Route: Equatable, Sendable {
    case createBookmark
    case createWork
    case searchBookmarks
    case searchWorks

    public var pathSuffix: String {
        switch self {
        case .createBookmark: return "/bookmarks"
        case .createWork: return "/works"
        case .searchBookmarks: return "/bookmarks/search"
        case .searchWorks: return "/works/search"
        }
    }
}

public enum AO3AdminRoute: Equatable, Sendable {
    case login, logout
    case password(AO3DevisePasswordRoute)
    case activities(id: Int?)
    case banners(AO3AdminBannerRoute)
    case blacklistedEmails(id: Int?)
    case settings(AO3ResourceAction<Int>)
    case skins(AO3AdminSkinsRoute)
    case spam(bulkUpdate: Bool)
    case supportNotices(AO3AdminBannerRoute) // /admin/notices/support
    case userCreations(id: Int, action: AO3AdminCreationAction)
    case users(AO3AdminUsersRoute)
    case troubleshootUser(id: Int) // /admin/admin_users/troubleshoot/:id
    case invitations(AO3AdminInvitationsRoute)
    case api(AO3AdminAPIRoute)

    public var pathSuffix: String {
        switch self {
        case .login: return "/login"
        case .logout: return "/logout"
        case .password(let route): return "/password" + route.pathSuffix
        case .activities(let id): return id.map { "/activities/\($0)" } ?? "/activities"
        case .banners(let route): return "/banners" + route.pathSuffix
        case .blacklistedEmails(let id): return id.map { "/blacklisted_emails/\($0)" } ?? "/blacklisted_emails"
        case .settings(let action): return "/settings" + action.pathSuffix
        case .skins(let route): return "/skins" + route.pathSuffix
        case .spam(let bulk): return bulk ? "/spam/bulk_update" : "/spam"
        case .supportNotices(let route): return "/notices/support" + route.pathSuffix
        case .userCreations(let id, let action): return "/user_creations/\(id)" + action.pathSuffix
        case .users(let route): return "/users" + route.pathSuffix
        case .troubleshootUser(let id): return "/admin_users/troubleshoot/\(id)"
        case .invitations(let route): return "/invitations" + route.pathSuffix
        case .api(let route): return "/api" + route.pathSuffix
        }
    }
}

public enum AO3AdminBannerRoute: Equatable, Sendable {
    case index, new
    case show(id: Int), edit(id: Int), confirmDelete(id: Int)
    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        case .confirmDelete(let id): return "/\(id)/confirm_delete"
        }
    }
}

public enum AO3AdminSkinsRoute: Equatable, Sendable {
    case index, new, indexRejected, indexApproved, update
    case show(id: Int), edit(id: Int)
    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .indexRejected: return "/index_rejected"
        case .indexApproved: return "/index_approved"
        case .update: return "/update"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3AdminCreationAction: String, Equatable, Sendable {
    case destroy = ""
    case hide = "/hide"
    case setSpam = "/set_spam"
    case confirmRemovePseud = "/confirm_remove_pseud"
    case removePseud = "/remove_pseud"
    public var pathSuffix: String { rawValue }
}

public enum AO3AdminUsersRoute: Equatable, Sendable {
    case index, bulkSearch, update, updateStatus, updateNextOfKin
    case show(id: String)
    case confirmDeleteUserCreations(id: String)
    case destroyUserCreations(id: String)
    case activate(id: String)
    case checkUser(id: String)
    case creations(id: String)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .bulkSearch: return "/bulk_search"
        case .update: return "/update"
        case .updateStatus: return "/update_status"
        case .updateNextOfKin: return "/update_next_of_kin"
        case .show(let id): return "/\(id)"
        case .confirmDeleteUserCreations(let id): return "/\(id)/confirm_delete_user_creations"
        case .destroyUserCreations(let id): return "/\(id)/destroy_user_creations"
        case .activate(let id): return "/\(id)/activate"
        case .checkUser(let id): return "/\(id)/check_user"
        case .creations(let id): return "/\(id)/creations"
        }
    }
}

public enum AO3AdminInvitationsRoute: Equatable, Sendable {
    case index, new, inviteFromQueue, grantInvitesToUsers, find
    case show(id: Int), edit(id: Int)
    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .inviteFromQueue: return "/invite_from_queue"
        case .grantInvitesToUsers: return "/grant_invites_to_users"
        case .find: return "/find"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3AdminAPIRoute: Equatable, Sendable {
    case index, new
    case show(id: Int), edit(id: Int)
    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .new: return "/new"
        case .show(let id): return "/\(id)"
        case .edit(let id): return "/\(id)/edit"
        }
    }
}

public enum AO3AdminsRoute: Equatable, Sendable {
    case index
    case totp(adminID: String, route: AO3AdminTOTPRoute)

    public var pathSuffix: String {
        switch self {
        case .index: return ""
        case .totp(let id, let route): return "/\(id)/totp" + route.pathSuffix
        }
    }
}

public enum AO3AdminTOTPRoute: Equatable, Sendable {
    case root, new, showBackupCodes, confirmDisable, disable, reauthenticateCreate
    public var pathSuffix: String {
        switch self {
        case .root: return ""
        case .new: return "/new"
        case .showBackupCodes: return "/show_backup_codes"
        case .confirmDisable: return "/confirm_disable"
        case .disable: return "/disable"
        case .reauthenticateCreate: return "/reauthenticate_create"
        }
    }
}
