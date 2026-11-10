//
//  AO3FicMetadata.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation


// MARK: Metadata Structure

public struct AO3FicMetadata: Identifiable, Sendable, Codable, AO3Subscribable, AO3FicModel {
    public var id: Int
    
    public var displayName: String
    public var summary: String?
    public var notes: String?
    public var endNotes: String?
    public var authors: [AO3AuthorLink]
    
    public var fandoms: [String]
    public var relationships: [String]
    public var characters: [String]
    public var additionalTags: [String]
    public var series: [AO3SeriesLink]
    public var collections: [AO3CollectionLink]
    public var chapters: [AO3ChapterLink]
    
    public var publishDate: Date
    public var updateDate: Date?
    public var wordCount: Int
    
    public var currentChapterCount: Int
    public var expectedChapterCount: Int? // nil represents the "?"

    public var isRestricted: Bool
    public var language: String
    
    public var status: AO3FicStatus
    public var contentRating: AO3ContentRating
    public var relationshipCategories: [AO3RelationshipCategory]
    public var archiveWarnings: [AO3ContentWarning]
    
    public var commentCount: Int
    public var kudosCount: Int
    public var bookmarkCount: Int
    public var hitCount: Int?
    
    public var workSkinCSS: String?
    
    // MARK: Subscribable
    
    public var subscriptionRecordID: Int?
    public var subscribableID: Int { return self.id }
    
    public static var responseType: ResponseType { return .work }
}

// MARK: Enums

public enum AO3ContentRating: String, Comparable, Sendable, Codable {
    case generalAudiences
    case teenAndUpAudiences
    case mature
    case explicit
    
    case notGiven
    
    public var displayName: LocalizedStringResource {
        switch self {
        case .generalAudiences: return "General Audiences"
        case .teenAndUpAudiences: return "Teen And Up Audiences"
        case .mature: return "Mature"
        case .explicit: return "Explicit"
        case .notGiven: return "Not Given"
        }
    }
    
    public var isAdult: Bool {
        switch self {
        case .explicit: return true
            
        default: return false
        }
    }
    
    static public func <(lhs: AO3ContentRating, rhs: AO3ContentRating) -> Bool {
        return lhs.value < rhs.value
    }
    
    fileprivate var value: Int {
        switch self {
        case .generalAudiences: return 0
        case .teenAndUpAudiences: return 1
        case .mature: return 2
        case .explicit: return 3
        case .notGiven: return -1
        }
    }
}

public enum AO3RelationshipCategory: String, Sendable, Codable {
    /// Female/Female Relationships
    case fxf
    /// Female/Male Relationships
    case fxm
    /// No romantic or sexual relationships, or relationships which are not the main focus of the work
    case gen
    /// Male/Male Relationships
    case mxm
    /// More than one kind of relationship, or a relationship with multiple partners
    case multi
    /// Other Relationships
    case other
    
    public var displayName: LocalizedStringResource {
        switch self {
        case .fxf: return "F/F"
        case .fxm: return "F/M"
        case .gen: return "Gen"
        case .mxm: return "M/M"
        case .multi: return "Multi"
        case .other: return "Other Relationships"
        }
    }
    
    public var displayDescription: LocalizedStringResource {
        switch self {
        case .fxf: return "Female/Female Relationships"
        case .fxm: return "Female/Male Relationships"
        case .gen: return "No romantic or sexual relationships, or relationships which are not the main focus of the work"
        case .mxm: return "Male/Male Relationships"
        case .multi: return "More than one kind of relationship, or a relationship with multiple partners"
        case .other: return "Other Relationships"
        }
    }
}

public enum AO3ContentWarning: String, Sendable, Codable {
    /// Indicates that the work may contain detailed, extended descriptions of graphic violence.
    case graphic
    /// Indicates that the work may include the death of a character who is prominently featured.
    case majorDeath
    /// Indicates that the work may contain non-consensual sexual activity.
    case nonCon
    /// Indicates that the work may contain descriptions or depictions of explicit activity involving characters under the age of eighteen.
    case underage
    
    /// This non-specific warning tag means that the work may contain content pertaining to any of the Archive Warnings.
    case noArchiveWarnings
    /// If this warning tag is used in the absence of other Archive Warnings, it means that the work does not contain detailed content pertaining to any of the four specific Archive Warnings. However, the work may briefly reference an Archive Warning topic and/or contain other intense or unpleasant content that is not covered by any of the Archive Warnings.
    case noWarningsApply
    /// Indicates that this is an external work.
    case externalWork
    
    public var displayName: LocalizedStringResource {
        switch self {
        case .graphic: return "Graphic Depictions of Violence"
        case .majorDeath: return "Major Character Death"
        case .nonCon: return "Rape / Non-Con"
        case .underage: return "Underage Content"
        case .noArchiveWarnings: return "Creator Chose Not To Use Archive Warnings"
        case .noWarningsApply: return "No Archive Warnings Apply"
        case .externalWork: return "External Work"
        }
    }
    
    public var displayDescription: LocalizedStringResource {
        switch self {
        case .graphic: return "The work may contain detailed, extended descriptions of graphic violence."
        case .majorDeath: return "The work may include the death of a character who is prominently featured."
        case .nonCon: return "The work may contain non-consensual sexual activity."
        case .underage: return "The work may contain descriptions or depictions of explicit activity involving characters under the age of eighteen."
        case .noArchiveWarnings: return "This non-specific warning tag means that the work may contain content pertaining to any of the Archive Warnings."
        case .noWarningsApply: return "If this warning tag is used in the absence of other Archive Warnings, it means that the work does not contain detailed content pertaining to any of the four specific Archive Warnings. However, the work may briefly reference an Archive Warning topic and/or contain other intense or unpleasant content that is not covered by any of the Archive Warnings."
        case .externalWork: return "This is an external work; please consult the work itself for warnings."
        }
    }
}

public enum AO3FicStatus: String, Sendable, Codable {
    case completed
    case inProgress
    case unknown
    
    public var displayName: LocalizedStringResource {
        switch self {
        case .completed: return "Completed"
        case .inProgress: return "In-Progress"
        case .unknown: return "Unknown"
        }
    }
    
    public var displayDescription: LocalizedStringResource {
        switch self {
        case .completed: return "This work is completed!/This prompt is filled!"
        case .inProgress: return "This is a work in progress or is incomplete/unfulfilled."
        case .unknown: return "This work's status is unknown."
        }
    }
    
}
