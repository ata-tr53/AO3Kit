//
//  AO3UserRoutes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

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
