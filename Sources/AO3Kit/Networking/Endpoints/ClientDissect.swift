//
//  ClientDissect.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

extension AO3Client {
    
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
            return .support

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
    
}
