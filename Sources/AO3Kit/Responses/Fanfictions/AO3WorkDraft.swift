//
//  AO3WorkDraft.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public enum AO3WorkCommentPermissions: String, Sendable, Codable, Hashable {
    case all = "enable_all"
    case registeredUsersOnly = "disable_anon"
    case none = "disable_all"
}

public struct AO3WorkDraft: Sendable, Codable, Hashable {
    public var title: String
    public var summary: String
    public var notes: String
    public var endNotes: String

    public var rating: AO3ContentRating
    public var archiveWarnings: [AO3ContentWarning]
    public var categories: [AO3RelationshipCategory]
    public var fandoms: [String]
    public var relationships: [String]
    public var characters: [String]
    public var additionalTags: [String]

    public var languageID: Int
    public var workSkinID: Int?
    public var collections: [String]
    public var recipients: [String]

    public var isRestricted: Bool
    public var isModeratedComments: Bool
    public var commentPermissions: AO3WorkCommentPermissions

    public var isMultiChapter: Bool
    /// Expected total chapter count (`nil` renders as `"?"` when `isMultiChapter` is `true`).
    public var expectedChapters: Int?
    public var chapterTitle: String?
    public var chapterContent: String

    /// Pseud display names to credit on the work. Empty uses the account's default pseud.
    public var pseudNames: [String]
    /// When `true`, submits as a draft (`Save As Draft`) instead of publishing immediately (`Post`).
    public var saveAsDraft: Bool

    public init(
        title: String,
        chapterContent: String,
        fandoms: [String],
        rating: AO3ContentRating = .notGiven,
        archiveWarnings: [AO3ContentWarning] = [.noArchiveWarnings],
        categories: [AO3RelationshipCategory] = [],
        relationships: [String] = [],
        characters: [String] = [],
        additionalTags: [String] = [],
        summary: String = "",
        notes: String = "",
        endNotes: String = "",
        languageID: Int = 1,
        workSkinID: Int? = nil,
        collections: [String] = [],
        recipients: [String] = [],
        isRestricted: Bool = false,
        isModeratedComments: Bool = false,
        commentPermissions: AO3WorkCommentPermissions = .all,
        isMultiChapter: Bool = false,
        expectedChapters: Int? = nil,
        chapterTitle: String? = nil,
        pseudNames: [String] = [],
        saveAsDraft: Bool = false
    ) {
        self.title = title
        self.chapterContent = chapterContent
        self.fandoms = fandoms
        self.rating = rating
        self.archiveWarnings = archiveWarnings
        self.categories = categories
        self.relationships = relationships
        self.characters = characters
        self.additionalTags = additionalTags
        self.summary = summary
        self.notes = notes
        self.endNotes = endNotes
        self.languageID = languageID
        self.workSkinID = workSkinID
        self.collections = collections
        self.recipients = recipients
        self.isRestricted = isRestricted
        self.isModeratedComments = isModeratedComments
        self.commentPermissions = commentPermissions
        self.isMultiChapter = isMultiChapter
        self.expectedChapters = expectedChapters
        self.chapterTitle = chapterTitle
        self.pseudNames = pseudNames
        self.saveAsDraft = saveAsDraft
    }
}

public struct AO3WorkTagsDraft: Sendable, Codable, Hashable {
    public var rating: AO3ContentRating
    public var archiveWarnings: [AO3ContentWarning]
    public var categories: [AO3RelationshipCategory]
    public var fandoms: [String]
    public var relationships: [String]
    public var characters: [String]
    public var additionalTags: [String]
    public var languageID: Int?

    public init(
        rating: AO3ContentRating = .notGiven,
        archiveWarnings: [AO3ContentWarning] = [.noArchiveWarnings],
        categories: [AO3RelationshipCategory] = [],
        fandoms: [String] = [],
        relationships: [String] = [],
        characters: [String] = [],
        additionalTags: [String] = [],
        languageID: Int? = nil
    ) {
        self.rating = rating
        self.archiveWarnings = archiveWarnings
        self.categories = categories
        self.fandoms = fandoms
        self.relationships = relationships
        self.characters = characters
        self.additionalTags = additionalTags
        self.languageID = languageID
    }
}

public struct AO3WorkImportDraft: Sendable, Codable, Hashable {
    public var urls: [URL]
    /// `true` imports multiple URLs as chapters of a single work; `false` imports each URL as a separate work.
    public var importAsChapters: Bool
    public var overrideTags: Bool
    public var postWithoutPreview: Bool
    public var isRestricted: Bool
    public var fandoms: [String]
    public var rating: AO3ContentRating?
    public var archiveWarnings: [AO3ContentWarning]
    public var languageID: Int?

    public init(
        urls: [URL],
        importAsChapters: Bool = false,
        overrideTags: Bool = false,
        postWithoutPreview: Bool = false,
        isRestricted: Bool = false,
        fandoms: [String] = [],
        rating: AO3ContentRating? = nil,
        archiveWarnings: [AO3ContentWarning] = [],
        languageID: Int? = nil
    ) {
        self.urls = urls
        self.importAsChapters = importAsChapters
        self.overrideTags = overrideTags
        self.postWithoutPreview = postWithoutPreview
        self.isRestricted = isRestricted
        self.fandoms = fandoms
        self.rating = rating
        self.archiveWarnings = archiveWarnings
        self.languageID = languageID
    }
}

public struct AO3ChapterDraft: Sendable, Codable, Hashable {
    public var title: String
    public var summary: String
    public var notes: String
    public var endNotes: String
    public var content: String
    public var position: Int?
    /// Total expected chapters (e.g., `"?"` or `"10"`).
    public var wipLength: String?
    public var publishedAt: Date?
    public var pseudNames: [String]
    public var saveAsDraft: Bool

    public init(
        content: String,
        title: String = "",
        summary: String = "",
        notes: String = "",
        endNotes: String = "",
        position: Int? = nil,
        wipLength: String? = nil,
        publishedAt: Date? = nil,
        pseudNames: [String] = [],
        saveAsDraft: Bool = false
    ) {
        self.content = content
        self.title = title
        self.summary = summary
        self.notes = notes
        self.endNotes = endNotes
        self.position = position
        self.wipLength = wipLength
        self.publishedAt = publishedAt
        self.pseudNames = pseudNames
        self.saveAsDraft = saveAsDraft
    }
}

// MARK: - Canonical AO3 Form String Mappings

internal extension AO3ContentRating {
    var ao3FormString: String {
        switch self {
        case .notGiven: return "Not Rated"
        case .generalAudiences: return "General Audiences"
        case .teenAndUpAudiences: return "Teen And Up Audiences"
        case .mature: return "Mature"
        case .explicit: return "Explicit"
        }
    }
}

internal extension AO3ContentWarning {
    var ao3FormString: String? {
        switch self {
        case .noArchiveWarnings: return "Creator Chose Not To Use Archive Warnings"
        case .graphic: return "Graphic Depictions Of Violence"
        case .majorDeath: return "Major Character Death"
        case .noWarningsApply: return "No Archive Warnings Apply"
        case .nonCon: return "Rape/Non-Con"
        case .underage: return "Underage Sex"
        case .externalWork: return nil
        }
    }
}

internal extension AO3RelationshipCategory {
    var ao3FormString: String {
        switch self {
        case .fxf: return "F/F"
        case .fxm: return "F/M"
        case .gen: return "Gen"
        case .mxm: return "M/M"
        case .multi: return "Multi"
        case .other: return "Other"
        }
    }
}
