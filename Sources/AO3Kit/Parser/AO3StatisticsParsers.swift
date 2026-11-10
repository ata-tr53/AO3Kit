//
//  AO3Statistics.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 4.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    static func parseUserStatistics(html: String, username: String) throws -> AO3UserStatistics {
        try withDocument(html: html) { doc in
            if (try doc.body()?.text() ?? "").contains("You currently have no works posted to the Archive.") {
                throw AO3ClientError.noDataFound
            }
            
            func digitsInt(_ text: String?) -> Int {
                guard let text else { return 0 }
                return Int(text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            }
            
            let totalsList = try doc.select("dl.statistics.meta.group").first()
            let fandomElements = try doc.select("li.fandom.listbox.group").array()
            
            let fandoms: [AO3FandomStatistics] = try fandomElements.map { fandomElement in
                let fandomName = fandomElement.firstText("h5.heading") ?? "Unknown Fandom"
                let workElements = try fandomElement.select("ul.index.group > li").array()
                
                let works: [AO3WorkStatistics] = try workElements.compactMap { workElement in
                    guard let titleLink = try workElement.select("dt > a[href*='/works/']").first() else { return nil }
                    let workTitle = try titleLink.text()
                    let workID = Int(try titleLink.attr("href").replacingOccurrences(of: "/works/", with: "")) ?? 0
                    let statsList = try workElement.select("dl.stats").first()
                    
                    return AO3WorkStatistics(
                        id: workID,
                        workTitle: workTitle,
                        wordCount: digitsInt(workElement.firstText("dt > span.words")),
                        subscriptions: digitsInt(statsList?.firstText("dd.subscriptions")),
                        hits: digitsInt(statsList?.firstText("dd.hits")),
                        kudos: digitsInt(statsList?.firstText("dd.kudos")),
                        commentThreads: digitsInt(statsList?.firstText("dd.comments")),
                        bookmarks: digitsInt(statsList?.firstText("dd.bookmarks"))
                    )
                }
                
                return AO3FandomStatistics(fandomName: fandomName, works: works)
            }
            
            return AO3UserStatistics(
                id: username,
                userSubscriptions: digitsInt(totalsList?.firstText("dd.user.subscriptions")),
                totalKudos: digitsInt(totalsList?.firstText("dd.kudos")),
                totalCommentThreads: digitsInt(totalsList?.firstText("dd.comment.thread.count")),
                totalBookmarks: digitsInt(totalsList?.firstText("dd.bookmarks")),
                totalSubscriptions: digitsInt(totalsList?.firstText("dd.subscriptions:not(.user)")),
                totalWordCount: digitsInt(totalsList?.firstText("dd.words")),
                totalHits: digitsInt(totalsList?.firstText("dd.hits")),
                fandoms: fandoms
            )
        }
    }

}
