//
//  AO3Statistics.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 4.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - User Statistics Parser
    
    static func parseUserStatistics(html: String, username: String) throws -> AO3UserStatistics {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer { doc.empty() }
            
            let bodyText = try doc.body()?.text() ?? ""
            if bodyText.contains("You currently have no works posted to the Archive.") {
                throw AO3ClientError.noDataFound
            }
            
            func extractInt(from text: String?) -> Int {
                guard let text = text else { return 0 }
                let cleaned = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return Int(cleaned) ?? 0
            }
            
            let totalsList = try doc.select("dl.statistics.meta.group").first()
            
            let userSubs = extractInt(from: try totalsList?.select("dd.user.subscriptions").first()?.text())
            let totalKudos = extractInt(from: try totalsList?.select("dd.kudos").first()?.text())
            let totalThreads = extractInt(from: try totalsList?.select("dd.comment.thread.count").first()?.text())
            let totalBookmarks = extractInt(from: try totalsList?.select("dd.bookmarks").first()?.text())
            let totalSubs = extractInt(from: try totalsList?.select("dd.subscriptions:not(.user)").first()?.text())
            let totalWords = extractInt(from: try totalsList?.select("dd.words").first()?.text())
            let totalHits = extractInt(from: try totalsList?.select("dd.hits").first()?.text())
            
            var fandoms: [AO3FandomStatistics] = []
            
            let fandomElements = try doc.select("li.fandom.listbox.group").array()
            
            for fandomElement in fandomElements {
                let fandomName = try fandomElement.select("h5.heading").first()?.text() ?? "Unknown Fandom"
                var works: [AO3WorkStatistics] = []
                
                let workElements = try fandomElement.select("ul.index.group > li").array()
                
                for workElement in workElements {
                    
                    guard let titleLink = try workElement.select("dt > a[href*='/works/']").first() else { continue }
                    let workTitle = try titleLink.text()
                    let href = try titleLink.attr("href")
                    let workID = Int(href.replacingOccurrences(of: "/works/", with: "")) ?? 0
                    
                    let wordString = try workElement.select("dt > span.words").first()?.text()
                    let workWords = extractInt(from: wordString)
                    
                    let statsList = try workElement.select("dl.stats").first()
                    
                    let workSubs = extractInt(from: try statsList?.select("dd.subscriptions").first()?.text())
                    let workHits = extractInt(from: try statsList?.select("dd.hits").first()?.text())
                    let workKudos = extractInt(from: try statsList?.select("dd.kudos").first()?.text())
                    let workThreads = extractInt(from: try statsList?.select("dd.comments").first()?.text())
                    let workBookmarks = extractInt(from: try statsList?.select("dd.bookmarks").first()?.text())
                    
                    let workStat = AO3WorkStatistics(
                        id: workID,
                        workTitle: workTitle,
                        wordCount: workWords,
                        subscriptions: workSubs,
                        hits: workHits,
                        kudos: workKudos,
                        commentThreads: workThreads,
                        bookmarks: workBookmarks
                    )
                    
                    works.append(workStat)
                }
                
                fandoms.append(AO3FandomStatistics(fandomName: fandomName, works: works))
            }
            
            return AO3UserStatistics(
                id: username,
                userSubscriptions: userSubs,
                totalKudos: totalKudos,
                totalCommentThreads: totalThreads,
                totalBookmarks: totalBookmarks,
                totalSubscriptions: totalSubs,
                totalWordCount: totalWords,
                totalHits: totalHits,
                fandoms: fandoms
            )
        }
    }

}
