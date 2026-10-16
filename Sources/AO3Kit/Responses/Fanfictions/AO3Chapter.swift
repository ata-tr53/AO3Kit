//
//  AO3Chapter.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

public struct AO3Chapter: Identifiable, Sendable, Codable, AO3Response {
    public var id: Int?
    
    public var index: Int
    public var title: String
    public var summary: String?
    public var notes: String?
    public var endNotes: String?
    
    public var authors: [AO3AuthorLink]
    public var publicationDate: Date?
    
    /// The actual text or HTML body of the chapter.
    public var content: String
    
    public static var responseType: ResponseType { return .chapter }
}


public struct AO3ChapterLink: Identifiable, Sendable, Codable, Hashable, Equatable, AO3Response {
    public var id: Int
    public var index: Int
    public var name: String
    
    /// can be found within /works/[workID]/navigate
    public var releaseDate: Date?
    
    public var workID: Int?
    
    public init(id: Int, index: Int, name: String, releaseDate: Date? = nil, workID: Int? = nil) {
        self.id = id
        self.index = index
        self.name = name
        self.releaseDate = releaseDate
        self.workID = workID
    }
    
    public var url: URL? {
        if let workID {
            return URL(string: "https://archiveofourown.org/works/\(workID)/chapters/\(self.id)")
        } else {
            return URL(string: "https://archiveofourown.org/chapters/\(self.id)")
        }
    }
    
    public static var responseType: ResponseType { return .chapter }
}


public extension Array where Element == AO3ChapterLink {
    var chapterIDs: [Int] {
        return self.compactMap { $0.id }
    }
    
    var chapterTitles: [Int: String] {
        var result: [Int: String] = [:]
        
        for link in self {
            result[link.id] = link.name
        }
        
        return result
    }
}
