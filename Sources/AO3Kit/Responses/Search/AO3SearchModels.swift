//
//  AO3SearchModels.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

// MARK: Work Search Filter

public struct AO3WorkSearchFilter: Sendable, Equatable, Hashable {
    public var query: String?
    public var title: String?
    public var creators: String?
    public var revisedAt: String?
    public var complete: Bool? // nil = all, true = complete only, false = WIP only
    public var crossovers: Bool? // nil = include, true = only crossovers, false = exclude
    public var singleChapterOnly: Bool = false
    public var wordCount: String? // e.g. ">10000" or "1000-5000"
    public var languageID: String? // e.g. "en"
    
    public var fandoms: [String] = []
    public var rating: AO3ContentRating?
    public var archiveWarnings: [AO3ContentWarning] = []
    public var categories: [AO3RelationshipCategory] = []
    public var characters: [String] = []
    public var relationships: [String] = []
    public var additionalTags: [String] = []
    
    public var excludedRatings: [AO3ContentRating] = []
    public var excludedWarnings: [AO3ContentWarning] = []
    public var excludedCategories: [AO3RelationshipCategory] = []
    public var excludedTags: [String] = []
    
    public var hits: String?
    public var kudosCount: String?
    public var commentsCount: String?
    public var bookmarksCount: String?
    
    public var sortColumn: SortColumn = .bestMatch
    public var sortDirection: SortDirection = .descending
    
    public init(
        query: String? = nil,
        title: String? = nil,
        creators: String? = nil,
        fandoms: [String] = [],
        rating: AO3ContentRating? = nil,
        sortColumn: SortColumn = .bestMatch,
        sortDirection: SortDirection = .descending
    ) {
        self.query = query
        self.title = title
        self.creators = creators
        self.fandoms = fandoms
        self.rating = rating
        self.sortColumn = sortColumn
        self.sortDirection = sortDirection
    }
    
    public enum SortColumn: String, Sendable, Codable, Hashable {
        case bestMatch = "_score"
        case author = "authors_to_sort_on"
        case title = "title_to_sort_on"
        case datePosted = "created_at"
        case dateUpdated = "revised_at"
        case wordCount = "word_count"
        case hits = "hits"
        case kudos = "kudos_count"
        case comments = "comments_count"
        case bookmarks = "bookmarks_count"
    }
    
    public enum SortDirection: String, Sendable, Codable, Hashable {
        case ascending = "asc"
        case descending = "desc"
    }
    
    internal var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [URLQueryItem(name: "commit", value: "Search")]
        func add(_ name: String, _ value: String?) {
            if let value, !value.isEmpty {
                items.append(URLQueryItem(name: "work_search[\(name)]", value: value))
            }
        }
        
        add("query", query)
        add("title", title)
        add("creators", creators)
        add("revised_at", revisedAt)
        if let complete { add("complete", complete ? "T" : "F") }
        if let crossovers { add("crossover", crossovers ? "T" : "F") }
        if singleChapterOnly { add("single_chapter", "1") }
        add("word_count", wordCount)
        add("language_id", languageID)
        
        if !fandoms.isEmpty { add("fandom_names", fandoms.joined(separator: ",")) }
        if let ratingID = rating?.ao3SearchTagID { add("rating_ids", String(ratingID)) }
        
        for warning in archiveWarnings {
            if let id = warning.ao3SearchTagID {
                items.append(URLQueryItem(name: "work_search[archive_warning_ids][]", value: String(id)))
            }
        }
        for category in categories {
            items.append(URLQueryItem(name: "work_search[category_ids][]", value: String(category.ao3SearchTagID)))
        }
        
        if !characters.isEmpty { add("character_names", characters.joined(separator: ",")) }
        if !relationships.isEmpty { add("relationship_names", relationships.joined(separator: ",")) }
        if !additionalTags.isEmpty { add("freeform_names", additionalTags.joined(separator: ",")) }
        
        for excludedRating in excludedRatings {
            items.append(URLQueryItem(name: "exclude_work_search[rating_ids][]", value: String(excludedRating.ao3SearchTagID)))
        }
        for excludedWarning in excludedWarnings {
            if let id = excludedWarning.ao3SearchTagID {
                items.append(URLQueryItem(name: "exclude_work_search[archive_warning_ids][]", value: String(id)))
            }
        }
        for excludedCategory in excludedCategories {
            items.append(URLQueryItem(name: "exclude_work_search[category_ids][]", value: String(excludedCategory.ao3SearchTagID)))
        }
        if !excludedTags.isEmpty { add("excluded_tag_names", excludedTags.joined(separator: ",")) }
        
        add("hits", hits)
        add("kudos_count", kudosCount)
        add("comments_count", commentsCount)
        add("bookmarks_count", bookmarksCount)
        add("sort_column", sortColumn.rawValue)
        add("sort_direction", sortDirection.rawValue)
        
        return items
    }
}

// MARK: - 2. Bookmark Search Filter

public struct AO3BookmarkSearchFilter: Sendable, Equatable, Hashable {
    public var workQuery: String?
    public var bookmarkNotesQuery: String?
    public var workTags: [String] = []
    public var bookmarkerTags: [String] = []
    public var bookmarker: String?
    public var recsOnly: Bool = false
    public var withNotesOnly: Bool = false
    public var sortColumn: SortColumn = .dateBookmarked
    
    public init(
        workQuery: String? = nil,
        bookmarkNotesQuery: String? = nil,
        bookmarker: String? = nil,
        recsOnly: Bool = false,
        withNotesOnly: Bool = false,
        sortColumn: SortColumn = .dateBookmarked
    ) {
        self.workQuery = workQuery
        self.bookmarkNotesQuery = bookmarkNotesQuery
        self.bookmarker = bookmarker
        self.recsOnly = recsOnly
        self.withNotesOnly = withNotesOnly
        self.sortColumn = sortColumn
    }
    
    public enum SortColumn: String, Sendable, Codable, Hashable {
        case dateBookmarked = "created_at"
        case dateUpdated = "bookmarkable_date"
    }
    
    internal var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [URLQueryItem(name: "commit", value: "Search Bookmarks")]
        func add(_ name: String, _ value: String?) {
            if let value, !value.isEmpty {
                items.append(URLQueryItem(name: "bookmark_search[\(name)]", value: value))
            }
        }
        add("bookmarkable_query", workQuery)
        add("bookmark_query", bookmarkNotesQuery)
        if !workTags.isEmpty { add("other_tag_names", workTags.joined(separator: ",")) }
        if !bookmarkerTags.isEmpty { add("other_bookmark_tag_names", bookmarkerTags.joined(separator: ",")) }
        add("bookmarker", bookmarker)
        if recsOnly { add("rec", "1") }
        if withNotesOnly { add("with_notes", "1") }
        add("sort_column", sortColumn.rawValue)
        return items
    }
}

// MARK: Tag Search Filter & Result

public struct AO3TagSearchFilter: Sendable, Equatable, Hashable {
    public var name: String?
    public var fandoms: [String] = []
    public var type: TagType? = nil
    public var wranglingStatus: WranglingStatus? = nil
    public var sortColumn: SortColumn = .name
    public var sortDirection: AO3WorkSearchFilter.SortDirection = .ascending
    
    public init(
        name: String? = nil,
        fandoms: [String] = [],
        type: TagType? = nil,
        wranglingStatus: WranglingStatus? = nil,
        sortColumn: SortColumn = .name,
        sortDirection: AO3WorkSearchFilter.SortDirection = .ascending
    ) {
        self.name = name
        self.fandoms = fandoms
        self.type = type
        self.wranglingStatus = wranglingStatus
        self.sortColumn = sortColumn
        self.sortDirection = sortDirection
    }
    
    public enum TagType: String, Sendable, Codable, Hashable {
        case fandom = "Fandom"
        case character = "Character"
        case relationship = "Relationship"
        case freeform = "Freeform"
    }
    
    public enum WranglingStatus: String, Sendable, Codable, Hashable {
        case canonical = "canonical"
        case nonCanonical = "noncanonical"
        case synonymous = "synonymous"
        case canonicalOrSynonymous = "canonical_synonymous"
        case nonCanonicalAndNonSynonymous = "noncanonical_nonsynonymous"
    }
    
    public enum SortColumn: String, Sendable, Codable, Hashable {
        case name = "name"
        case dateCreated = "created_at"
        case uses = "uses"
    }
    
    internal var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [URLQueryItem(name: "commit", value: "Search Tags")]
        if let name, !name.isEmpty { items.append(URLQueryItem(name: "tag_search[name]", value: name)) }
        if !fandoms.isEmpty { items.append(URLQueryItem(name: "tag_search[fandoms]", value: fandoms.joined(separator: ","))) }
        if let type { items.append(URLQueryItem(name: "tag_search[type]", value: type.rawValue)) }
        if let wranglingStatus { items.append(URLQueryItem(name: "tag_search[wrangling_status]", value: wranglingStatus.rawValue)) }
        items.append(URLQueryItem(name: "tag_search[sort_column]", value: sortColumn.rawValue))
        items.append(URLQueryItem(name: "tag_search[sort_direction]", value: sortDirection.rawValue))
        return items
    }
}

public struct AO3TagSearchResult: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public var id: String { name }
    public let name: String
    public let type: AO3TagSearchFilter.TagType?
    public let isCanonical: Bool
    public let usesCount: Int
    
    public static var responseType: ResponseType { .tag }
}

// MARK: People Search Filter & Result

public struct AO3PeopleSearchFilter: Sendable, Equatable, Hashable {
    public var query: String?
    public var name: String?
    public var fandom: String?
    
    public init(query: String? = nil, name: String? = nil, fandom: String? = nil) {
        self.query = query
        self.name = name
        self.fandom = fandom
    }
    
    internal var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [URLQueryItem(name: "commit", value: "Search People")]
        if let query, !query.isEmpty { items.append(URLQueryItem(name: "people_search[query]", value: query)) }
        if let name, !name.isEmpty { items.append(URLQueryItem(name: "people_search[name]", value: name)) }
        if let fandom, !fandom.isEmpty { items.append(URLQueryItem(name: "people_search[fandom]", value: fandom)) }
        return items
    }
}

public struct AO3PersonSearchResult: Identifiable, Sendable, Codable, Hashable, AO3AuthorModel {
    public var id: String { "\(author.id)/\(author.pseudID)" }
    public var username: String { author.id }
    
    public let author: AO3AuthorLink
    public let workCount: Int
    public let bookmarkCount: Int
    
    public static var responseType: ResponseType { .user }
}

// MARK: Internal Tag ID Mappings for AO3 Search

internal extension AO3ContentRating {
    var ao3SearchTagID: Int {
        switch self {
        case .notGiven: return 9
        case .generalAudiences: return 10
        case .teenAndUpAudiences: return 11
        case .mature: return 12
        case .explicit: return 13
        }
    }
}

internal extension AO3ContentWarning {
    var ao3SearchTagID: Int? {
        switch self {
        case .noArchiveWarnings: return 14
        case .noWarningsApply: return 16
        case .graphic: return 17
        case .majorDeath: return 18
        case .nonCon: return 19
        case .underage: return 20
        case .externalWork: return nil
        }
    }
}

internal extension AO3RelationshipCategory {
    var ao3SearchTagID: Int {
        switch self {
        case .gen: return 21
        case .fxm: return 22
        case .mxm: return 23
        case .other: return 24
        case .fxf: return 116
        case .multi: return 2246
        }
    }
}
