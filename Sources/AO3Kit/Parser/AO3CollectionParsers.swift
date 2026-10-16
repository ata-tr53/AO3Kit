//
//  AO3CollectionParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - Collection Profile Parser
    
    static func parseCollectionProfile(html: String, collectionID: String) throws -> AO3Collection {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer { doc.empty() }
            
            // Display Name
            let headerLink = try doc.select("h2.heading a[href^='/collections/']").first()
            let displayName = try headerLink?.text() ?? collectionID
            
            // Icon
            var icon: AO3Image? = nil
            if let imgElement = try doc.select("div.primary.header.module img.icon").first() {
                let src = try imgElement.attr("src")
                if !src.isEmpty {
                    let fullURL = src.hasPrefix("http") ? src : "https://archiveofourown.org\(src)"
                    icon = AO3Image(
                        description: try imgElement.attr("alt"),
                        source: fullURL
                    )
                }
            }
            
            // Maintainers
            let maintainerElements = try doc.select("dl.meta group, dl.meta dd.maintainers a").array()
            let maintainers: [AO3AuthorLink] = try maintainerElements.compactMap { el in
                let href = try el.attr("href")
                let name = try el.text()
                let components = href.components(separatedBy: "/")
                guard components.count >= 3, components[1] == "users" else { return nil }
                
                let userID = components[2].removingPercentEncoding ?? components[2]
                let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
                
                return AO3AuthorLink(id: userID, pseudID: pseudID, displayedName: name, profilePicture: nil)
            }
            
            // Parent Collection
            var parentCollection: AO3CollectionLink? = nil
            if let parentLink = try doc.select("div#dashboard ul.navigation.actions a:contains(Parent Collection)").first() {
                let href = try parentLink.attr("href")
                if let parentID = href.components(separatedBy: "/").last, !parentID.isEmpty {
                    let cleanID = parentID.removingPercentEncoding ?? parentID
                    parentCollection = AO3CollectionLink(
                        id: cleanID,
                        name: cleanID
                    )
                }
            }
            
            // Options (The Bitmask!)
            var options = AO3CollectionOptions(rawValue: 0)
            
            let statusText = try doc.select("p.type").first()?.text() ?? ""
            
            if !statusText.contains("Closed") { options.insert(.open) }
            if statusText.contains("Moderated") { options.insert(.moderated) }
            if statusText.contains("Unrevealed") { options.insert(.unrevealed) }
            if statusText.contains("Anonymous") { options.insert(.anonymous) }
            
            // Challenge Type
            var challengeType: AO3ChallengeType? = nil
            let challengeText = try doc.select("dl.meta dt:contains(Challenge) + dd").text()
            if challengeText.contains("Gift Exchange") {
                challengeType = .giftExchange
            } else if challengeText.contains("Prompt Meme") {
                challengeType = .promptMeme
            }
            
            // Profile Text Fields
            // The summary lives in the primary header module
            let summaryHTML = try doc.select("div.primary.header.module blockquote.userstuff").first()?.html()
            
            let rulesHTML = try doc.select("div.collection.rules.module blockquote.userstuff").first()?.html()
            let faqHTML = try doc.select("div.collection.faq.module blockquote.userstuff").first()?.html()
            
            // Dashboard Statistics
            func parseStat(for path: String) -> Int {
                do {
                    guard let link = try doc.select("div#dashboard ul.navigation.actions a[href$='/\(path)']").first(),
                          let text = try? link.text() else { return 0 }
                    
                    if let regex = try? NSRegularExpression(pattern: "\\(([\\d,]+)\\)", options: []),
                       let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                       let range = Range(match.range(at: 1), in: text) {
                        return Int(String(text[range]).replacingOccurrences(of: ",", with: "")) ?? 0
                    }
                } catch { return 0 }
                return 0
            }
            
            // Date
            let dateText = try doc.select("dl.meta dt:contains(Active since) + dd").text().trimmingCharacters(in: .whitespacesAndNewlines)
            let activeDate = DateFormatter.ao3DateFormatter.date(from: dateText) ?? Date()
            
            return AO3Collection(
                id: collectionID,
                displayName: displayName,
                icon: icon,
                maintainers: maintainers,
                parentCollection: parentCollection,
                summaryHTML: summaryHTML,
                faqHTML: faqHTML,
                rulesHTML: rulesHTML,
                options: options,
                challengeType: challengeType,
                fandomCount: parseStat(for: "fandoms"),
                workCount: parseStat(for: "works"),
                bookmarkCount: parseStat(for: "bookmarks"),
                subCollectionCount: parseStat(for: "collections"),
                date: activeDate
            )
        }
    }
    
    // MARK: - Collection Previews Parser
    
    static func parseCollectionPreviews(html: String) throws -> [AO3CollectionPreview] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer { doc.empty() }
            
            let blurbs = try doc.select("li.collection.picture.blurb.group").array()
            
            return blurbs.compactMap { element in
                do {
                    // ID and Display Name
                    let headerLink = try element.select("h4.heading a[href^='/collections/']").first()
                    let href = try headerLink?.attr("href") ?? ""
                    let id = href.components(separatedBy: "/").last ?? ""
                    let displayName = try headerLink?.text() ?? id
                    
                    guard !id.isEmpty else { return nil }
                    
                    // Icon
                    var icon: AO3Image? = nil
                    if let imgElement = try element.select("div.icon img.icon").first() {
                        let src = try imgElement.attr("src")
                        let alt = try imgElement.attr("alt")
                        if !src.isEmpty {
                            let fullURL = src.hasPrefix("http") ? src : "https://archiveofourown.org\(src)"
                            icon = AO3Image(
                                description: alt.isEmpty ? nil : alt,
                                source: fullURL
                            )
                        }
                    }
                    
                    // Maintainers
                    let ownerElements = try element.select("h4.heading a.owner").array()
                    let maintainers: [AO3AuthorLink] = try ownerElements.compactMap { el in
                        let ownerHref = try el.attr("href")
                        let name = try el.text()
                        let components = ownerHref.components(separatedBy: "/")
                        guard components.count >= 3 else { return nil }
                        
                        let userID = components[2].removingPercentEncoding ?? components[2]
                        let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
                        
                        return AO3AuthorLink(id: userID, pseudID: pseudID, displayedName: name, profilePicture: nil)
                    }
                    
                    // Date
                    let dateText = try element.select("p.datetime").text()
                    let date = DateFormatter.ao3BlurbDateFormatter.date(from: dateText) ?? Date()
                    
                    // Summary
                    let summaryHTML = try element.select("blockquote.userstuff.summary").html()
                    
                    // Options
                    var options = AO3CollectionOptions(rawValue: 0)
                    let statusText = try element.select("p.type").text()
                    
                    if !statusText.contains("Closed") { options.insert(.open) }
                    if statusText.contains("Moderated") { options.insert(.moderated) }
                    if statusText.contains("Unrevealed") { options.insert(.unrevealed) }
                    if statusText.contains("Anonymous") { options.insert(.anonymous) }
                    
                    // Stats
                    let worksText = try element.select("dl.stats dd.works a").text().replacingOccurrences(of: ",", with: "")
                    let bookmarksText = try element.select("dl.stats dd.bookmarks a").text().replacingOccurrences(of: ",", with: "")
                    
                    return AO3CollectionPreview(
                        id: id,
                        displayName: displayName,
                        icon: icon,
                        maintainers: maintainers,
                        summaryHTML: summaryHTML.isEmpty ? nil : summaryHTML,
                        options: options,
                        workCount: Int(worksText) ?? 0,
                        bookmarkCount: Int(bookmarksText) ?? 0,
                        date: date
                    )
                } catch {
                    print("⚠️ Failed to parse collection preview: \(error)")
                    return nil
                }
            }
        }
    }



}
