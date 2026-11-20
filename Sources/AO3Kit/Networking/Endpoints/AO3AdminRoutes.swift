//
//  AO3AdminRoutes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

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
