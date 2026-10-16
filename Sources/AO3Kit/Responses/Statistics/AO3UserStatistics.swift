//
//  AO3UserStatistics.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 4.10.2026.
//


import Foundation

public struct AO3UserStatistics: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: String
    
    // MARK: - Global Totals
    public var userSubscriptions: Int
    public var totalKudos: Int
    public var totalCommentThreads: Int
    public var totalBookmarks: Int
    public var totalSubscriptions: Int
    public var totalWordCount: Int
    public var totalHits: Int
    
    // MARK: - Work Breakdown
    public var fandoms: [AO3FandomStatistics]
    
    public var countDictionary: [String: Int] {
        return [
            "User Subscriptions": self.userSubscriptions,
            "Kudos": self.totalKudos,
            "Comment Threads": self.totalCommentThreads,
            "Bookmarks": self.totalBookmarks,
            "Subscriptions": self.totalSubscriptions,
            "Word Count": self.totalWordCount,
            "Hits": self.totalHits
        ]
    }
    
    public static var responseType: ResponseType { return .stats }
}

public struct AO3FandomStatistics: Identifiable, Sendable, Codable, Hashable {
    public var id: String { fandomName }
    public var fandomName: String
    public var works: [AO3WorkStatistics]
}

public struct AO3WorkStatistics: Identifiable, Sendable, Codable, Hashable {
    public let id: Int // workID
    public var workTitle: String
    
    public var wordCount: Int
    
    public var subscriptions: Int
    public var hits: Int
    public var kudos: Int
    public var commentThreads: Int
    public var bookmarks: Int
    
    public var countDictionary: [String: Int] {
        return [
            "Subscriptions": self.subscriptions,
            "Hits": self.hits,
            "Kudos": self.kudos,
            "Comment Threads": self.commentThreads,
            "Bookmarks": self.bookmarks,
            "WordCount": self.wordCount
        ]
    }
}
