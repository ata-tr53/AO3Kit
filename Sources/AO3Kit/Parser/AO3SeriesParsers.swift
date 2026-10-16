//
//  AO3SeriesParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - Series Preview (Blurb) Parser
    
    static func parseSeriesPreviews(html: String) throws -> [AO3SeriesPreview] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            let blurbs = try doc.select("li.series.blurb").array()
            
            return blurbs.compactMap { element in
                do {
                    return try parseSeriesPreview(from: element)
                } catch {
                    print("⚠️ Failed to parse a series preview: \(error)")
                    return nil
                }
            }
        }
    }

    internal static func parseSeriesPreview(from element: Element) throws -> AO3SeriesPreview {
        
        // ID
        let idString = try element.attr("id").replacingOccurrences(of: "series_", with: "")
        guard let id = Int(idString) else { throw AO3ClientError.invalidData }
        
        // Name & Authors
        let name = try element.select("h4.heading a[href^='/series/']").first()?.text() ?? "Unknown Series"
        
        let authorElements = try element.select("h4.heading a[rel=author]").array()
        let creators: [AO3AuthorLink] = try authorElements.compactMap { el in
            let href = try el.attr("href")
            let authorName = try el.text()
            
            let components = href.components(separatedBy: "/")
            guard components.count >= 3, components[1] == "users" else { return nil }
            
            let userID = components[2].removingPercentEncoding ?? components[2]
            let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
            
            return AO3AuthorLink(id: userID, pseudID: pseudID, displayedName: authorName)
        }
        
        // Fandoms & Tags
        let fandoms = try element.select("h5.fandoms a.tag").array().map { try $0.text() }
        let relationships = try element.select("li.relationships a.tag").array().map { try $0.text() }
        let characters = try element.select("li.characters a.tag").array().map { try $0.text() }
        let additionalTags = try element.select("li.freeforms a.tag").array().map { try $0.text() }
        
        // Date & Summary
        let dateText = try element.select("p.datetime").first()?.text() ?? ""
        let date = DateFormatter.ao3BlurbDateFormatter.date(from: dateText) ?? Date()
        let description = extractText(from: try element.select("blockquote.summary").first())
        
        // Required Tags (The Square Icons)
        let ratingText = try element.select("span.rating").attr("title")
        
        let highestRatingText = ratingText.components(separatedBy: ", ").first ?? ""
        let contentRating = mapContentRating(highestRatingText)
        
        let categoryText = try element.select("span.category").attr("title")
        let relationshipCategories = categoryText.components(separatedBy: ", ").compactMap { mapRelationshipCategory($0.trimmingCharacters(in: .whitespaces)) }
        
        let warningsText = try element.select("span.warnings").attr("title")
        let archiveWarnings = warningsText.components(separatedBy: ", ").compactMap { mapContentWarning($0.trimmingCharacters(in: .whitespaces)) }
        
        let statusText = try element.select("span.iswip").attr("title")
        let status: AO3FicStatus = (statusText == "Complete Series") ? .completed : .inProgress
        
        // Stats
        let wordCount = parseInt(try element.select("dd.words").first()?.text()) ?? 0
        let ficCount = parseInt(try element.select("dd.works").first()?.text()) ?? 0
        let bookmarks = parseInt(try element.select("dd.bookmarks").first()?.text()) ?? 0
        
        return AO3SeriesPreview(
            id: id,
            name: name,
            creators: creators,
            updateDate: date,
            description: description,
            wordCount: wordCount,
            ficCount: ficCount,
            bookmarks: bookmarks,
            status: status,
            contentRating: contentRating,
            relationshipCategories: relationshipCategories,
            archiveWarnings: archiveWarnings,
            fandoms: fandoms,
            relationships: relationships,
            characters: characters,
            additionalTags: additionalTags
        )
    }
    
    
    // MARK: - Full Series Parser
    
    static func parseSeries(html: String, seriesID: Int) throws -> AO3Series {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            // Title & Authors
            let name = try doc.select("h2.heading").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Series"
            
            let authorElements = try doc.select("dl.series.meta.group dt:contains(Creator:) + dd a[rel=author]").array()
            let creators: [AO3AuthorLink] = try authorElements.compactMap { el in
                let href = try el.attr("href")
                let authorName = try el.text()
                
                let components = href.components(separatedBy: "/")
                guard components.count >= 3, components[1] == "users" else { return nil }
                
                let userID = components[2].removingPercentEncoding ?? components[2]
                let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
                
                return AO3AuthorLink(id: userID, pseudID: pseudID, displayedName: authorName)
            }
            
            // Dates
            let beginDateText = try doc.select("dl.series.meta.group dt:contains(Series Begun:) + dd").first()?.text() ?? ""
            let updateDateText = try doc.select("dl.series.meta.group dt:contains(Series Updated:) + dd").first()?.text() ?? ""
            
            let startDate = DateFormatter.ao3DateFormatter.date(from: beginDateText) ?? Date()
            let updateDate = DateFormatter.ao3DateFormatter.date(from: updateDateText)
            
            // Description & Notes
            let description = extractText(from: try doc.select("dl.series.meta.group dt:contains(Description:) + dd blockquote.userstuff").first())
            let notes = extractText(from: try doc.select("dl.series.meta.group dt:contains(Notes:) + dd blockquote.userstuff").first())
            
            // Stats & Status
            let completeText = try doc.select("dl.series.meta.group dt:contains(Complete:) + dd").first()?.text() ?? "No"
            let status: AO3FicStatus = (completeText == "Yes") ? .completed : .inProgress
            
            let wordCount = parseInt(try doc.select("dl.stats dd.words").first()?.text()) ?? 0
            let ficCount = parseInt(try doc.select("dl.stats dd.works").first()?.text()) ?? 0
            let bookmarks = parseInt(try doc.select("dl.stats dd.bookmarks").first()?.text()) ?? 0
            
            // Parse the Fics
            let ficElements = try doc.select("ul.series.work.index.group li.work.blurb").array()
            let fics: [AO3FicPreview] = ficElements.compactMap { element in
                do {
                    return try parseFicPreview(from: element)
                } catch {
                    print("⚠️ Failed to parse a fic within series \(seriesID): \(error)")
                    return nil
                }
            }
            
            let subscriptionRecordID = try parseSubscriptionID(from: doc)
            
            return AO3Series(
                id: seriesID,
                name: name,
                creators: creators,
                startDate: startDate,
                updateDate: updateDate,
                description: description,
                notes: notes,
                wordCount: wordCount,
                ficCount: ficCount,
                bookmarks: bookmarks,
                status: status,
                fics: fics,
                subscriptionRecordID: subscriptionRecordID
            )
        }
    }
}
