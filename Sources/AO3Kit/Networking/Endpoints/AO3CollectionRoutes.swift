//
//  AO3CollectionRoutes.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

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
