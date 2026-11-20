//
//  AO3SiteRoutes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

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
