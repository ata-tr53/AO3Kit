//
//  AO3Client.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Synchronization
import Foundation
import OSLog

@Observable
public final class AO3Client: Sendable {
    
    internal let session: URLSession
    internal let userAgent: String
    
    public let cache: AO3Cache
    internal let imageStore: AO3ImageStore
    internal let taskTracker = AO3TaskTracker()
    
    internal let bypassAdultBlock: Bool
    internal let cullRequestsOnOutage: Bool
    
    public init(
        session: URLSession = .shared,
        userAgent: String = "AO3Kit/1.0 (Compatible; iOS/macOS)",
        bypassAdultBlock: Bool = true,
        cache: AO3Cache = AO3Cache(
            storageStrategy: .memoryOnly,
            memoryCountLimit: 20
        ),
        imageStore: AO3ImageStore = AO3ImageStore(
            storageStrategy: .both,
            memoryCountLimit: 50,
            diskByteLimit: 100 * 1024 * 1024
        ),
        cullRequestsOnOutage: Bool = true
    ) {
        self.session = session
        self.userAgent = userAgent
        self.bypassAdultBlock = bypassAdultBlock
        self.cache = cache
        self.imageStore = imageStore
        self.cullRequestsOnOutage = cullRequestsOnOutage
        
        if bypassAdultBlock {
            if let adultCookie = HTTPCookie(properties: [
                .domain: "archiveofourown.org",
                .path: "/",
                .name: "view_adult",
                .value: "true",
                .secure: "TRUE",
                .expires: Date().addingTimeInterval(60 * 60 * 24 * 365) // 1 year
            ]) {
                self.session.configuration.httpCookieStorage?.setCookie(adultCookie)
            }
        }
    }
    
    static internal let validHosts: Set<String> = [
        "archiveofourown.org",
        "archiveofourown.com",
        "archiveofourown.net",
        "archiveofourown.gay",
        "ao3.org",
        "archive.transformativeworks.org",
        "insecure.archiveofourown.org"
    ]
    
    //MARK: CSRF Tokens
    
    @ObservationIgnored
    private let csrfTokenLock = Mutex<String?>(nil)
    
    internal var cachedCSRFToken: String? {
        get { csrfTokenLock.withLock { $0 } }
        set { csrfTokenLock.withLock { $0 = newValue } }
    }
    
    //MARK: Current User
    
    @ObservationIgnored
    private let usernameLock = Mutex<String?>(nil)

    public internal(set) var cachedUsername: String? {
        get { usernameLock.withLock { $0 } }
        set { usernameLock.withLock { $0 = newValue } }
    }

    internal func resolveCurrentUsername() async throws -> String {
        if let existing = cachedUsername {
            return existing
        }
        guard isLoggedIn else {
            throw AO3ClientError.requiresRegistration
        }
        let user = try await fetchCurrentUser(fallbackStrategy: .useCache)
        self.cachedUsername = user.id
        return user.id
    }
    
    //-----------------------------------------------------------------------------------
    
    // MARK: URL Recognition
    public static func isAO3(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return validHosts.contains { url.absoluteString.contains($0) }
        }
        
        if validHosts.contains(host) {
            return true
        }
        
        return validHosts.contains { host.hasSuffix(".\($0)") }
    }
    
    public static func dissect(url: URL) -> AO3Endpoint {
        guard isAO3(url: url) else { return .unknown }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        let pathParts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard !pathParts.isEmpty else { return .home }

        let root = pathParts[0]
        let remainder = Array(pathParts.dropFirst())

        switch root {
        // MARK: Works
        case "works":
            guard let first = remainder.first else { return .worksCollection(.index) }
            switch first {
            case "search": return .worksSearch(queryItems: queryItems)
            case "new": return .worksCollection(.new)
            case "import": return .worksCollection(.import)
            case "clean_work_search_params": return .worksCollection(.cleanWorkSearchParams)
            case "collected": return .worksCollection(.collected)
            case "drafts": return .worksCollection(.drafts)
            case "update_multiple": return .worksCollection(.updateMultiple)
            case "edit_multiple":
                if let idStr = remainder.dropFirst().first, let id = Int(idStr) {
                    return .worksCollection(.editMultiple(id: id))
                }
                return .unknown
            case "confirm_delete_multiple":
                if let idStr = remainder.dropFirst().first, let id = Int(idStr) {
                    return .worksCollection(.confirmDeleteMultiple(id: id))
                }
                return .unknown
            case "delete_multiple":
                if let idStr = remainder.dropFirst().first, let id = Int(idStr) {
                    return .worksCollection(.deleteMultiple(id: id))
                }
                return .unknown
            default:
                guard let id = Int(first) else { return .unknown }
                return .work(id: id, route: AO3WorkRoute.dissect(remainder: Array(remainder.dropFirst()), queryItems: queryItems))
            }

        // MARK: Chapters
        case "chapters":
            guard let first = remainder.first else { return .chaptersCollection(.index) }
            if first == "new" { return .chaptersCollection(.new) }
            guard let id = Int(first) else { return .unknown }
            return .chapter(id: id, route: AO3ChapterRoute.dissect(remainder: Array(remainder.dropFirst()), queryItems: queryItems))

        // MARK: Users
        case "users":
            guard let first = remainder.first else { return .usersCollection(.index) }
            switch first {
            case "login": return .usersCollection(.login)
            case "logout": return .usersCollection(.logout)
            case "sign_up": return .usersCollection(.signUp)
            case "edit": return .usersCollection(.editRegistration)
            case "cancel": return .usersCollection(.cancelRegistration)
            case "password":
                switch remainder.dropFirst().first {
                case "new": return .usersCollection(.password(.new))
                case "edit": return .usersCollection(.password(.edit))
                case "reset": return .usersCollection(.password(.reset))
                default: return .usersCollection(.password(.root))
                }
            default:
                return .user(username: first, route: AO3UserRoute.dissect(remainder: Array(remainder.dropFirst()), queryItems: queryItems))
            }

        // MARK: Collections
        case "collections":
            guard let first = remainder.first else { return .collectionsIndex(.index) }
            switch first {
            case "new": return .collectionsIndex(.new)
            case "list_challenges": return .collectionsIndex(.listChallenges)
            case "list_ge_challenges": return .collectionsIndex(.listGEChallenges)
            case "list_pm_challenges": return .collectionsIndex(.listPMChallenges)
            default:
                return .collection(name: first, route: AO3CollectionRoute.dissect(remainder: Array(remainder.dropFirst())))
            }

        // MARK: Tags
        case "tags":
            guard let first = remainder.first else { return .tagsCollection(.index) }
            switch first {
            case "search": return .tagsSearch(queryItems: queryItems)
            case "new": return .tagsCollection(.new)
            case "show_hidden": return .tagsCollection(.showHidden)
            default:
                let decodedTag = (first.removingPercentEncoding ?? first).ao3TagDecoded
                return .tag(name: decodedTag, route: AO3TagRoute.dissect(remainder: Array(remainder.dropFirst())))
            }

        // MARK: Series
        case "series":
            guard let first = remainder.first else { return .seriesCollection(.index) }
            if first == "new" { return .seriesCollection(.new) }
            guard let id = Int(first) else { return .unknown }
            return .series(id: id, route: AO3SeriesRoute.dissect(remainder: Array(remainder.dropFirst())))

        // MARK: Bookmarks
        case "bookmarks":
            guard let first = remainder.first else { return .bookmarks(.index) }
            switch first {
            case "search": return .bookmarksSearch(queryItems: queryItems)
            case "new": return .bookmarks(.new)
            default:
                guard let id = Int(first) else { return .unknown }
                let rest = Array(remainder.dropFirst())
                switch rest.first {
                case "edit": return .bookmarks(.edit(id: id))
                case "confirm_delete": return .bookmarks(.confirmDelete(id: id))
                case "share": return .bookmarks(.share(id: id))
                case "collection_items":
                    let action = AO3ResourceAction.dissect(remainder: Array(rest.dropFirst()), parseID: Int.init) ?? .index
                    return .bookmarks(.collectionItems(bookmarkID: id, action: action))
                default: return .bookmarks(.show(id: id))
                }
            }

        // MARK: Comments
        case "comments":
            guard let first = remainder.first else { return .comments(.index) }
            switch first {
            case "new": return .comments(.new)
            case "hide_comments": return .comments(.hideComments)
            case "show_comments": return .comments(.showComments)
            case "add_comment_reply": return .comments(.addCommentReply)
            case "cancel_comment_reply": return .comments(.cancelCommentReply)
            case "cancel_comment_edit": return .comments(.cancelCommentEdit)
            case "delete_comment": return .comments(.deleteComment)
            case "cancel_comment_delete": return .comments(.cancelCommentDelete)
            default:
                guard let id = Int(first) else { return .unknown }
                let rest = Array(remainder.dropFirst())
                guard let sub = rest.first else { return .commentThread(id: id) }
                switch sub {
                case "edit": return .comments(.edit(id: id))
                case "approve": return .comments(.approve(id: id))
                case "reject": return .comments(.reject(id: id))
                case "review": return .comments(.review(id: id))
                case "freeze": return .comments(.freeze(id: id))
                case "unfreeze": return .comments(.unfreeze(id: id))
                case "hide": return .comments(.hide(id: id))
                case "unhide": return .comments(.unhide(id: id))
                case "comments":
                    let action = AO3ResourceAction.dissect(remainder: Array(rest.dropFirst()), parseID: Int.init) ?? .index
                    return .comments(.replies(commentID: id, action: action))
                default: return .commentThread(id: id)
                }
            }

        // MARK: People & Kudos & Autocomplete
        case "people":
            return remainder.first == "search" ? .peopleSearch(queryItems: queryItems) : .people(.index)
        case "kudos":
            return .kudos
        case "autocomplete":
            guard let type = remainder.first else { return .unknown }
            return .autocomplete(type: AO3AutocompleteType(rawValue: type), queryItems: queryItems)

        // MARK: Downloads
        case "downloads":
            guard remainder.count >= 2, let workID = Int(remainder[0]) else { return .unknown }
            let filename = remainder[1]
            guard let dotIndex = filename.lastIndex(of: ".") else { return .unknown }
            let title = String(filename[..<dotIndex]).replacingOccurrences(of: "_", with: " ")
            let format = String(filename[filename.index(after: dotIndex)...])
            return .download(workID: workID, title: title, format: format)

        // MARK: Admin Posts (News)
        case "admin_posts":
            guard let first = remainder.first else { return .news(id: nil) }
            if first == "drafts" { return .news(id: nil, route: .drafts) }
            if first == "new" { return .news(id: nil, route: .new) }
            guard let id = Int(first) else { return .unknown }
            return .news(id: id, route: AO3NewsRoute.dissect(remainder: Array(remainder.dropFirst())))

        // MARK: Media, Fandoms, Wrangling & Tag Sets
        case "media":
            guard let first = remainder.first else { return .media(.index) }
            if first == "new" { return .media(.new) }
            let rest = Array(remainder.dropFirst())
            switch rest.first {
            case "edit": return .media(.edit(id: first))
            case "fandoms":
                let action = AO3ResourceAction.dissect(remainder: Array(rest.dropFirst()), parseID: { $0 }) ?? .index
                return .media(.fandoms(mediaID: first, action: action))
            default: return .media(.show(id: first))
            }

        case "fandoms":
            guard let first = remainder.first else { return .fandom(.index) }
            if first == "new" { return .fandom(.new) }
            if first == "unassigned" { return .fandom(.unassigned) }
            switch remainder.dropFirst().first {
            case "edit": return .fandom(.edit(id: first))
            case "show": return .fandom(.explicitShow(id: first))
            default: return .fandom(.show(id: first))
            }

        case "tag_wranglings":
            guard let first = remainder.first else { return .tagWrangling(.index) }
            if first == "new" { return .tagWrangling(.new) }
            if first == "wrangle" { return .tagWrangling(.wrangle) }
            guard let id = Int(first) else { return .unknown }
            return .tagWrangling(remainder.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))

        case "tag_wranglers":
            guard let first = remainder.first else { return .tagWrangler(.index) }
            if first == "new" { return .tagWrangler(.new) }
            switch remainder.dropFirst().first {
            case "edit": return .tagWrangler(.edit(id: first))
            case "report_csv": return .tagWrangler(.reportCSV(id: first))
            default: return .tagWrangler(.show(id: first))
            }

        case "unsorted_tags":
            guard let first = remainder.first else { return .unsortedTags(.index) }
            if first == "new" { return .unsortedTags(.new) }
            if first == "mass_update" { return .unsortedTags(.massUpdate) }
            guard let id = Int(first) else { return .unknown }
            return .unsortedTags(remainder.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))

        case "tag_sets":
            guard let first = remainder.first else { return .tagSet(.index) }
            if first == "new" { return .tagSet(.new) }
            if first == "show_options" { return .tagSet(.showOptions) }
            guard let id = Int(first) else { return .unknown }
            let rest = Array(remainder.dropFirst())
            switch rest.first {
            case "edit": return .tagSet(.edit(id: id))
            case "batch_load": return .tagSet(.batchLoad(id: id))
            case "do_batch_load": return .tagSet(.doBatchLoad(id: id))
            case "confirm_delete": return .tagSet(.confirmDelete(id: id))
            case "associations":
                return .tagSet(.associations(tagSetID: id, updateMultiple: rest.dropFirst().first == "update_multiple"))
            case "nominations":
                let nRest = Array(rest.dropFirst())
                switch nRest.first {
                case "new": return .tagSet(.nominations(tagSetID: id, route: .new))
                case "update_multiple": return .tagSet(.nominations(tagSetID: id, route: .updateMultiple))
                case "destroy_multiple": return .tagSet(.nominations(tagSetID: id, route: .destroyMultiple))
                case "confirm_destroy_multiple": return .tagSet(.nominations(tagSetID: id, route: .confirmDestroyMultiple))
                case let ns? where Int(ns) != nil:
                    let nid = Int(ns)!
                    switch nRest.dropFirst().first {
                    case "edit": return .tagSet(.nominations(tagSetID: id, route: .edit(id: nid)))
                    case "confirm_delete": return .tagSet(.nominations(tagSetID: id, route: .confirmDelete(id: nid)))
                    default: return .tagSet(.nominations(tagSetID: id, route: .show(id: nid)))
                    }
                default: return .tagSet(.nominations(tagSetID: id, route: .index))
                }
            default: return .tagSet(.show(id: id))
            }

        case "tag_nominations":
            guard let idStr = remainder.first, let id = Int(idStr) else { return .unknown }
            return .tagNomination(id: id)

        case "tag_wrangling_requests":
            return .tagWranglingRequests(remainder.first == "update_multiple" ? .updateMultiple : .index)

        case "wrangling_guidelines":
            return .wranglingGuidelines(dissectManagedArticle(remainder: remainder))

        // MARK: External, Related, Serial Works, Gifts, Challenges
        case "external_works":
            guard let first = remainder.first else { return .externalWork(.index) }
            if first == "new" { return .externalWork(.new) }
            if first == "fetch" { return .externalWork(.fetch) }
            guard let id = Int(first) else { return .unknown }
            let rest = Array(remainder.dropFirst())
            switch rest.first {
            case "edit": return .externalWork(.edit(id: id))
            case "bookmarks":
                return .externalWork(.bookmarks(externalWorkID: id, action: AO3ResourceAction.dissect(remainder: Array(rest.dropFirst()), parseID: Int.init) ?? .index))
            case "related_works":
                return .externalWork(.relatedWorks(externalWorkID: id, action: AO3ResourceAction.dissect(remainder: Array(rest.dropFirst()), parseID: Int.init) ?? .index))
            default: return .externalWork(.show(id: id))
            }

        case "related_works":
            return .relatedWork(AO3ResourceAction.dissect(remainder: remainder, parseID: Int.init) ?? .index)
        case "serial_works":
            return .serialWork(AO3ResourceAction.dissect(remainder: remainder, parseID: Int.init) ?? .index)
        case "external_authors":
            return .externalAuthor(AO3ExternalAuthorRoute.dissect(remainder: remainder))

        case "gifts":
            if let idStr = remainder.first, let id = Int(idStr), remainder.dropFirst().first == "toggle_rejected" {
                return .gift(.toggleRejected(id: id))
            }
            return .gift(.index)

        case "challenges":
            guard let sub = remainder.first, let route = AO3ChallengeRoute(rawValue: sub) else { return .unknown }
            return .challenge(route)

        // MARK: Invitations, Claims & Orphans
        case "invitations":
            return .invitation(AO3ResourceAction.dissect(remainder: remainder, parseID: { $0 }) ?? .index)

        case "user_invite_requests":
            guard let first = remainder.first else { return .userInviteRequest(.index) }
            if first == "new" { return .userInviteRequest(.new) }
            if first == "update" { return .userInviteRequest(.update) }
            guard let id = Int(first) else { return .unknown }
            return .userInviteRequest(remainder.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id))

        case "invite_requests":
            switch remainder.first {
            case nil: return .inviteRequest(.index)
            case "manage": return .inviteRequest(.manage)
            case "status": return .inviteRequest(.status)
            case "resend": return .inviteRequest(.resend)
            case "show": return .inviteRequest(.showAction)
            case let s? where Int(s) != nil: return .inviteRequest(.item(id: Int(s)!))
            default: return .unknown
            }

        case "signup":
            return .signup(invitationToken: remainder.first)
        case "claim":
            guard let token = remainder.first else { return .unknown }
            return .claim(invitationToken: token)
        case "complete_claim":
            guard let token = remainder.first else { return .unknown }
            return .completeClaim(invitationToken: token)
        case "activate":
            guard let id = remainder.first else { return .unknown }
            return .activate(id: id)
        case "orphans":
            return .orphan(remainder.first == "new" ? .new : .index)

        // MARK: Skins, FAQ, Help, Reports, Redirect
        case "skins":
            guard let first = remainder.first else { return .skin(.index) }
            if first == "new" { return .skin(.new) }
            if first == "unset" { return .skin(.unset) }
            guard let id = Int(first) else { return .unknown }
            switch remainder.dropFirst().first {
            case "edit": return .skin(.edit(id: id))
            case "preview": return .skin(.preview(id: id))
            case "set": return .skin(.set(id: id))
            case "confirm_delete": return .skin(.confirmDelete(id: id))
            default: return .skin(.show(id: id))
            }

        case "known_issues":
            return .knownIssue(AO3ResourceAction.dissect(remainder: remainder, parseID: Int.init) ?? .index)

        case "faq":
            guard let first = remainder.first else { return .faq(.index) }
            switch first {
            case "new": return .faq(.new)
            case "manage": return .faq(.manage)
            case "update_positions": return .faq(.updatePositions)
            default:
                let rest = Array(remainder.dropFirst())
                switch rest.first {
                case "edit": return .faq(.edit(id: first))
                case "confirm_delete": return .faq(.confirmDelete(id: first))
                case "questions": return .faq(.questions(faqID: first, route: dissectManagedArticle(remainder: Array(rest.dropFirst()))))
                default: return .faq(.show(id: first))
                }
            }

        case "help":
            guard let page = remainder.first else { return .unknown }
            return .help(page: page)

        case "abuse_reports":
            return .abuseReport(remainder.first == "new" ? .new : .create)

        case "support":
            return .feedback()

        case "redirect":
            return .redirect(doRedirect: remainder.first == "do_redirect")

        case "menu":
            guard let sub = remainder.first, let route = AO3MenuRoute(rawValue: sub) else { return .unknown }
            return .menu(route)

        // MARK: i18n
        case "languages":
            guard let first = remainder.first else { return .language(.index) }
            if first == "new" { return .language(.new) }
            let rest = Array(remainder.dropFirst())
            switch rest.first {
            case "edit": return .language(.edit(id: first))
            case "works":
                return .language(.works(languageID: first, action: AO3ResourceAction.dissect(remainder: Array(rest.dropFirst()), parseID: Int.init) ?? .index))
            case "admin_posts":
                return .language(.adminPosts(languageID: first, action: AO3ResourceAction.dissect(remainder: Array(rest.dropFirst()), parseID: Int.init) ?? .index))
            default: return .language(.show(id: first))
            }

        case "locales":
            return .locale(AO3ResourceAction.dissect(remainder: remainder, parseID: { $0 }) ?? .index)

        // MARK: OpenDoors, API v2, Admin
        case "opendoors":
            switch remainder.first {
            case "tools":
                return .openDoors(remainder.dropFirst().first == "url_update" ? .toolsURLUpdate : .tools)
            case "external_authors":
                let eRest = Array(remainder.dropFirst())
                guard let first = eRest.first else { return .openDoors(.externalAuthors(.index)) }
                if first == "new" { return .openDoors(.externalAuthors(.new)) }
                guard let id = Int(first) else { return .unknown }
                switch eRest.dropFirst().first {
                case "edit": return .openDoors(.externalAuthors(.edit(id: id)))
                case "forward": return .openDoors(.externalAuthors(.forward(id: id)))
                default: return .openDoors(.externalAuthors(.show(id: id)))
                }
            default: return .unknown
            }

        case "api":
            guard remainder.first == "v2", remainder.count >= 2 else { return .unknown }
            let resource = remainder[1]
            let isSearch = remainder.count >= 3 && remainder[2] == "search"
            switch (resource, isSearch) {
            case ("bookmarks", true): return .apiV2(.searchBookmarks)
            case ("bookmarks", false): return .apiV2(.createBookmark)
            case ("works", true): return .apiV2(.searchWorks)
            case ("works", false): return .apiV2(.createWork)
            default: return .unknown
            }

        case "admin":
            return dissectAdmin(remainder: remainder)

        case "admins":
            guard let adminID = remainder.first, remainder.dropFirst().first == "totp" else {
                return .admins(.index)
            }
            let tRoute: AO3AdminTOTPRoute = switch remainder.dropFirst(2).first {
            case "new": .new
            case "show_backup_codes": .showBackupCodes
            case "confirm_disable": .confirmDisable
            case "disable": .disable
            case "reauthenticate_create": .reauthenticateCreate
            default: .root
            }
            return .admins(.totp(adminID: adminID, route: tRoute))

        default:
            if let page = AO3StaticPage(rawValue: root) { return .staticPage(page) }
            if let err = AO3ErrorRoute(rawValue: root) { return .error(err) }
            return .unknown
        }
    }

    private static func dissectManagedArticle(remainder: [String]) -> AO3ManagedArticleRoute {
        guard let first = remainder.first else { return .index }
        switch first {
        case "new": return .new
        case "manage": return .manage
        case "update_positions": return .updatePositions
        default:
            guard let id = Int(first) else { return .index }
            switch remainder.dropFirst().first {
            case "edit": return .edit(id: id)
            case "confirm_delete": return .confirmDelete(id: id)
            default: return .show(id: id)
            }
        }
    }

    private static func dissectAdmin(remainder: [String]) -> AO3Endpoint {
        guard let first = remainder.first else { return .unknown }
        let rest = Array(remainder.dropFirst())

        switch first {
        case "login": return .admin(.login)
        case "logout": return .admin(.logout)
        case "password":
            let sub: AO3DevisePasswordRoute = switch rest.first {
            case "new": .new
            case "edit": .edit
            case "reset": .reset
            default: .root
            }
            return .admin(.password(sub))
        case "activities":
            return .admin(.activities(id: rest.first.flatMap(Int.init)))
        case "banners":
            return .admin(.banners(dissectAdminBanner(remainder: rest)))
        case "blacklisted_emails":
            return .admin(.blacklistedEmails(id: rest.first.flatMap(Int.init)))
        case "settings":
            return .admin(.settings(AO3ResourceAction.dissect(remainder: rest, parseID: Int.init) ?? .index))
        case "skins":
            switch rest.first {
            case "new": return .admin(.skins(.new))
            case "index_rejected": return .admin(.skins(.indexRejected))
            case "index_approved": return .admin(.skins(.indexApproved))
            case "update": return .admin(.skins(.update))
            case let s? where Int(s) != nil:
                let id = Int(s)!
                return .admin(.skins(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id)))
            default: return .admin(.skins(.index))
            }
        case "spam":
            return .admin(.spam(bulkUpdate: rest.first == "bulk_update"))
        case "notices":
            guard rest.first == "support" else { return .unknown }
            return .admin(.supportNotices(dissectAdminBanner(remainder: Array(rest.dropFirst()))))
        case "user_creations":
            guard let idStr = rest.first, let id = Int(idStr) else { return .unknown }
            let action: AO3AdminCreationAction = switch rest.dropFirst().first {
            case "hide": .hide
            case "set_spam": .setSpam
            case "confirm_remove_pseud": .confirmRemovePseud
            case "remove_pseud": .removePseud
            default: .destroy
            }
            return .admin(.userCreations(id: id, action: action))
        case "users":
            switch rest.first {
            case nil: return .admin(.users(.index))
            case "bulk_search": return .admin(.users(.bulkSearch))
            case "update": return .admin(.users(.update))
            case "update_status": return .admin(.users(.updateStatus))
            case "update_next_of_kin": return .admin(.users(.updateNextOfKin))
            case let id?:
                switch rest.dropFirst().first {
                case "confirm_delete_user_creations": return .admin(.users(.confirmDeleteUserCreations(id: id)))
                case "destroy_user_creations": return .admin(.users(.destroyUserCreations(id: id)))
                case "activate": return .admin(.users(.activate(id: id)))
                case "check_user": return .admin(.users(.checkUser(id: id)))
                case "creations": return .admin(.users(.creations(id: id)))
                default: return .admin(.users(.show(id: id)))
                }
            }
        case "admin_users":
            guard rest.first == "troubleshoot", let idStr = rest.dropFirst().first, let id = Int(idStr) else {
                return .unknown
            }
            return .admin(.troubleshootUser(id: id))
        case "invitations":
            switch rest.first {
            case "new": return .admin(.invitations(.new))
            case "invite_from_queue": return .admin(.invitations(.inviteFromQueue))
            case "grant_invites_to_users": return .admin(.invitations(.grantInvitesToUsers))
            case "find": return .admin(.invitations(.find))
            case let s? where Int(s) != nil:
                let id = Int(s)!
                return .admin(.invitations(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id)))
            default: return .admin(.invitations(.index))
            }
        case "api":
            switch rest.first {
            case "new": return .admin(.api(.new))
            case let s? where Int(s) != nil:
                let id = Int(s)!
                return .admin(.api(rest.dropFirst().first == "edit" ? .edit(id: id) : .show(id: id)))
            default: return .admin(.api(.index))
            }
        default:
            return .unknown
        }
    }

    private static func dissectAdminBanner(remainder: [String]) -> AO3AdminBannerRoute {
        guard let first = remainder.first else { return .index }
        if first == "new" { return .new }
        guard let id = Int(first) else { return .index }
        switch remainder.dropFirst().first {
        case "edit": return .edit(id: id)
        case "confirm_delete": return .confirmDelete(id: id)
        default: return .show(id: id)
        }
    }

    
    //-----------------------------------------------------------------------------------
    
    // MARK: GET Helpers
    
    internal func fetchPage<T: Codable & Sendable & AO3Response>(
        for url: URL,
        page: Int,
        parser: (String) throws -> [T]
    ) async throws -> AO3PaginatedResult<T> {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw AO3ClientError.invalidURLComponents
        }
        
        var queryItems = components.queryItems?.filter { $0.name != "page" } ?? []
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            throw AO3ClientError.invalidURL
        }
        
        let html = try await performRequest(url: finalURL)
        
        let items = try parser(html)
        let pagination = try AO3Parser.parsePagination(html: html)
        
        return AO3PaginatedResult(
            items: items,
            currentPage: pagination.currentPage,
            totalPages: pagination.totalPages
        )
    }
    
    internal func fetchAll<T: Codable & Sendable & AO3Response>(
        for url: URL,
        maxPages: Int?,
        progressHandler: ((_ currentPage: Int, _ totalPages: Int) -> Void)? = nil,
        parser: (String) throws -> [T]
    ) async throws -> [T] {
        var allItems: [T] = []
        var currentPage = 1
        var totalPages = 1
        
        repeat {
            let result = try await fetchPage(for: url, page: currentPage, parser: parser)
            allItems.append(contentsOf: result.items)
            totalPages = result.totalPages
            
            let effectiveTotal = {
                if let maxPages {
                    return min(totalPages, maxPages)
                } else { return totalPages }
            }()
            progressHandler?(currentPage, effectiveTotal)
            
            if let max = maxPages, currentPage >= max {
                break
            }
            
            currentPage += 1
        } while currentPage <= totalPages
        
        return allItems
    }
    
    @inline(__always)
    internal func fetchPaginated<T: Codable & Sendable & AO3Response>(
        url: URL?,
        page: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) throws -> [T]
    ) async throws -> AO3PaginatedResult<T> {
        guard let validURL = url else { throw AO3ClientError.invalidURL }
        
        let cacheKey = validURL.absoluteString + "&page=\(page)"
        
        var staleFallbackData: AO3PaginatedResult<T>? = nil
        
        if fallbackStrategy != .bypassCache,
           let response: AO3CacheResponse<AO3PaginatedResult<T>> = try? await cache.get(forKey: cacheKey) {
            
            if let data = response.data {
                if response.state == .upToDate || fallbackStrategy == .prioritiseCache {
                    return data
                }
                
                staleFallbackData = data
            }
        }
        
        do {
            let result = try await taskTracker.track(key: cacheKey) {
                return try await self.fetchPage(for: validURL, page: page, parser: parser)
            }
            try? await cache.set(result, forKey: cacheKey)
            return result
        } catch {
            if fallbackStrategy == .useCache, let staleFallbackData {
                return staleFallbackData
            }
            throw error
        }
    }
    
    @inline(__always)
    internal func fetchPaginated<T: Codable & Sendable & AO3Response>(
        endpoint: AO3Endpoint,
        page: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) throws -> [T]
    ) async throws -> AO3PaginatedResult<T> {
        
        guard let url = endpoint.url(bypassAdultBlock: self.bypassAdultBlock) else {
            throw AO3ClientError.invalidEndpoint
        }
        
        return try await fetchPaginated(url: url, page: page, fallbackStrategy: fallbackStrategy, parser: parser)
    }

    
    @inline(__always)
    internal func fetchAllItems<T: Codable & Sendable & AO3Response>(
        url: URL?,
        maxPages: Int?,
        progressHandler: (@Sendable (Int, Int) -> Void)?,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) throws -> [T]
    ) async throws -> [T] {
        guard let validURL = url else { throw AO3ClientError.invalidURL }
        
        let limitSuffix = maxPages != nil ? "_limit_\(maxPages!)" : "_unlimited"
        let cacheKey = validURL.absoluteString + "_fetchAll" + limitSuffix
        
        var staleFallbackData: [T]? = nil
        
        if fallbackStrategy != .bypassCache,
           let response: AO3CacheResponse<[T]> = try? await cache.get(forKey: cacheKey) {
            
            if let data = response.data {
                if response.state == .upToDate || fallbackStrategy == .prioritiseCache {
                    progressHandler?(1, 1)
                    return data
                }
                
                staleFallbackData = data
            }
        }
        
        do {
            let result = try await taskTracker.track(key: cacheKey) {
                return try await self.fetchAll(for: validURL, maxPages: maxPages, progressHandler: progressHandler, parser: parser)
            }
            
            try? await cache.set(result, forKey: cacheKey)
            return result
        } catch {
            if fallbackStrategy == .useCache, let staleFallbackData {
                progressHandler?(1, 1)
                return staleFallbackData
            }
            throw error
        }
    }
    
    @inline(__always)
    internal func fetchAllItems<T: Codable & Sendable & AO3Response>(
        endpoint: AO3Endpoint,
        maxPages: Int?,
        progressHandler: (@Sendable (Int, Int) -> Void)?,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) throws -> [T]
    ) async throws -> [T] {
        
        guard let url = endpoint.url(bypassAdultBlock: self.bypassAdultBlock) else {
            throw AO3ClientError.invalidEndpoint
        }
        
        return try await fetchAllItems(url: url, maxPages: maxPages, progressHandler: progressHandler, fallbackStrategy: fallbackStrategy, parser: parser)
    }
    
    
    //-----------------------------------------------------------------------------------
    
    //MARK: POST Helpers
    
    internal func resolveCSRFToken(fallbackURL: URL, forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let existing = cachedCSRFToken {
            return existing
        }
        let html = try await performRequest(url: fallbackURL, method: .get)
        let token = try AO3Parser.parseCSRFToken(from: html)
        self.cachedCSRFToken = token
        return token
    }
    
    internal func performAuthenticatedFormPost(
        url: URL,
        tokenFallbackURL: URL,
        includeXHRHeaders: Bool = false,
        additionalHeaders: [String: String]? = nil,
        buildFormItems: (_ csrfToken: String) -> [URLQueryItem]
    ) async throws -> String {
        for isRetry in [false, true] {
            let token = try await resolveCSRFToken(fallbackURL: tokenFallbackURL, forceRefresh: isRetry)
            var headers = additionalHeaders ?? [:]
            if includeXHRHeaders {
                headers["X-Requested-With"] = "XMLHttpRequest"
                headers["X-CSRF-Token"] = token
                headers["Origin"] = "https://archiveofourown.org"
            }
            
            do {
                let responseHTML = try await performFormPost(
                    url: url,
                    formItems: buildFormItems(token),
                    referer: tokenFallbackURL,
                    additionalHeaders: headers
                )
                
                if !isRetry && responseHTML.contains("Authenticity token") {
                    continue
                }
                return responseHTML
            } catch let urlError as URLError where !isRetry && urlError.code.rawValue == 422 {
                continue
            }
        }
        throw AO3ClientError.invalidData
    }
    
    internal func performFormPost(
        url: URL,
        formItems: [URLQueryItem],
        referer: URL? = nil,
        additionalHeaders: [String: String]? = nil
    ) async throws -> String {
        var headers = additionalHeaders ?? [:]
        if let referer {
            headers["Referer"] = referer.absoluteString
        }
        let body = try formItems.formURLEncodedData()
        return try await performRequest(
            url: url,
            method: .post,
            body: body,
            headers: headers
        )
    }
    
    //-----------------------------------------------------------------------------------
    
    //MARK: Cache Helpers
    
    @inline(__always)
    internal func fetchCachedItem<T: Codable & Sendable>(
        url: URL?,
        cacheKey: String? = nil,
        headers: [String: String]? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) async throws -> T
    ) async throws -> T {
        guard let validURL = url else { throw AO3ClientError.invalidURL }
        let key = cacheKey ?? validURL.absoluteString
        
        var staleFallbackData: T? = nil
        
        if fallbackStrategy != .bypassCache,
            let response: AO3CacheResponse<T> = try? await cache.get(forKey: key) {
            
            if let data = response.data {
                if response.state == .upToDate || fallbackStrategy == .prioritiseCache {
                    return data
                }
                
                staleFallbackData = data
            }
        }
        
        do {
            let result = try await taskTracker.track(key: key) {
                let html = try await self.performRequest(url: validURL, method: .get, headers: headers)
                return try await parser(html)
            }
            try? await cache.set(result, forKey: key)
            return result
        } catch {
            if fallbackStrategy == .useCache, let staleData = staleFallbackData {
                return staleData
            }
            throw error
        }
    }
    
    @inline(__always)
    internal func fetchCachedItem<T: Codable & Sendable>(
        endpoint: AO3Endpoint,
        cacheKey: String? = nil,
        headers: [String: String]? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) async throws -> T
    ) async throws -> T {
        guard let url = endpoint.url(bypassAdultBlock: self.bypassAdultBlock) else {
            throw AO3ClientError.invalidURL
        }
        
        return try await fetchCachedItem(
            url: url,
            cacheKey: cacheKey,
            headers: headers,
            fallbackStrategy: fallbackStrategy,
            parser: parser
        )
    }



    //-----------------------------------------------------------------------------------
    
    //MARK: Networking
    
    internal func performRequest(
        url: URL,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [String: String]? = nil,
        maxRetries: Int = 3
    ) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

        if method == .post {
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        }
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let data = try await executeNetworkCall(request: request, maxRetries: maxRetries)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        if let freshToken = AO3Parser.extractCSRFTokenFast(from: html) {
            self.cachedCSRFToken = freshToken
        }
        
        if let detectedUser = AO3Parser.extractCurrentUsernameFast(from: html) {
            self.cachedUsername = detectedUser
        } else if html.contains(#"id="login""#) {
            self.cachedUsername = nil
        }
        
        guard !isAdultWarningPage(html: html) else {
            Logger.network.error("❌ AO3 adult content warning blocked fetch.")
            throw AO3ClientError.adultWarningBlocked
        }
        
        guard !isOnlyForRegisteredUsersPage(html: html) else {
            throw AO3ClientError.requiresRegistration
        }
        
        return html
    }
    
    private func executeNetworkCall(request: URLRequest, maxRetries: Int) async throws -> Data {
        var attempt = 0
        
        if cullRequestsOnOutage {
            let status = try? await AO3StatusMonitor.shared.currentStatus()
            if let isOperational = status?.isOperational, !isOperational {
                Logger.network.error("Request culled due to known system outage.")
                throw AO3ClientError.systemOutage
            }
        }
        
        while true {
            attempt += 1
            do {
                try Task.checkCancellation()
                try await AO3NetworkMonitor.shared.requireConnection()
                
                try await AO3RateLimiter.shared.waitIfNeeded()
                
                Logger.network.debug("Fetching \(request.url?.absoluteString ?? "unknown URL") (Attempt \(attempt))")
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if httpResponse.statusCode == 429 {
                    if let retryAfterString = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                       let retrySeconds = TimeInterval(retryAfterString) {
                        Logger.network.warning("429 Too Many Requests. AO3 requested backoff of \(retrySeconds)s.")
                        
                        await AO3RateLimiter.shared.imposePenalty(seconds: retrySeconds)
                    }
                    throw URLError(URLError.Code(rawValue: 429))
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
                }
                
                return data
                
            } catch {
                
                if error is CancellationError || (error as? URLError)?.code == .cancelled {
                    Logger.network.info("Task cancelled for \(request.url?.absoluteString ?? "")")
                    throw error
                }
                
                if shouldRetry(for: error, request: request, currentAttempt: attempt, maxRetries: maxRetries) {
                    let baseDelay = pow(2.0, Double(attempt)) // 2, 4, 8 seconds
                    let jitter = Double.random(in: 0...1.0)
                    let totalDelay = baseDelay + jitter
                    let backoffDelay = UInt64((totalDelay) * 1_000_000_000)
                    
                    Logger.network.debug("Request failed. Retrying in \(String(format: "%.2f", totalDelay))s...")
                    try await Task.sleep(nanoseconds: backoffDelay)
                    continue
                } else {
                    Logger.network.error("Network call failed after \(attempt) attempts: \(error.localizedDescription)")
                    throw error
                }
            }
        }
    }
    
    private func shouldRetry(for error: Error, request: URLRequest, currentAttempt: Int, maxRetries: Int) -> Bool {
        guard currentAttempt < maxRetries else { return false }
        
        if request.httpMethod?.uppercased() != "GET" {
            return false
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
                 URLError.Code(rawValue: 429),
                 URLError.Code(rawValue: 500),
                 URLError.Code(rawValue: 502),
                 URLError.Code(rawValue: 503),
                 URLError.Code(rawValue: 504):
                return true
            default: return false
            }
        }
        return false
    }


    internal func isAdultWarningPage(html: String) -> Bool {
        return html.contains("This work could have adult content")
    }
    
    internal func isOnlyForRegisteredUsersPage(html: String) -> Bool {
        return html.contains("This work is only available to registered users of the Archive.")
    }
    
    internal enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
}


public extension URL {
    var isAO3: Bool { return AO3Client.isAO3(url: self) }
}

internal extension String {
    /// Encodes special characters into AO3's custom asterisk format for URLs.
    var ao3TagEncoded: String {
        self.replacingOccurrences(of: "/", with: "*s*")
            .replacingOccurrences(of: "&", with: "*a*")
            .replacingOccurrences(of: ".", with: "*d*")
            .replacingOccurrences(of: "?", with: "*q*")
    }
    
    /// Decodes AO3's custom asterisk format back into standard text.
    var ao3TagDecoded: String {
        self.replacingOccurrences(of: "*s*", with: "/")
            .replacingOccurrences(of: "*a*", with: "&")
            .replacingOccurrences(of: "*d*", with: ".")
            .replacingOccurrences(of: "*q*", with: "?")
    }
}
