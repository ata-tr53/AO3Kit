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
        try parseElements(html: html, selector: "li.series.blurb", transform: parseSeriesPreview)
    }
    
    internal static func parseSeriesPreview(from element: Element) throws -> AO3SeriesPreview {
        let idString = try element.attr("id").replacingOccurrences(of: "series_", with: "")
        guard let id = Int(idString) else { throw AO3ClientError.invalidData }
        
        let name = element.firstText("h4.heading a[href^='/series/']") ?? "Unknown Series"
        let creators = parseAuthorLinks(in: element, selector: "h4.heading a[rel=author]")
        
        let fandoms = element.texts("h5.fandoms a.tag")
        let relationships = element.texts("li.relationships a.tag")
        let characters = element.texts("li.characters a.tag")
        let additionalTags = element.texts("li.freeforms a.tag")
        
        let date = DateFormatter.ao3BlurbDateFormatter.date(from: element.firstText("p.datetime") ?? "") ?? Date()
        let description = extractText(from: try element.select("blockquote.summary").first())
        
        let highestRatingText = (element.firstAttr("span.rating", "title") ?? "").components(separatedBy: ", ").first ?? ""
        let contentRating = mapContentRating(highestRatingText)
        
        let categoryText = element.firstAttr("span.category", "title") ?? ""
        let relationshipCategories = categoryText.components(separatedBy: ", ").compactMap {
            mapRelationshipCategory($0.trimmingCharacters(in: .whitespaces))
        }
        
        let warningsText = element.firstAttr("span.warnings", "title") ?? ""
        let archiveWarnings = warningsText.components(separatedBy: ", ").compactMap {
            mapContentWarning($0.trimmingCharacters(in: .whitespaces))
        }
        
        let status: AO3FicStatus = (element.firstAttr("span.iswip", "title") == "Complete Series") ? .completed : .inProgress
        
        return AO3SeriesPreview(
            id: id,
            name: name,
            creators: creators,
            updateDate: date,
            description: description,
            wordCount: element.firstInt("dd.words") ?? 0,
            ficCount: element.firstInt("dd.works") ?? 0,
            bookmarks: element.firstInt("dd.bookmarks") ?? 0,
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
        try withDocument(html: html) { doc in
            let name = doc.firstText("h2.heading") ?? "Unknown Series"
            let creators = parseAuthorLinks(in: doc, selector: "dl.series.meta.group dt:contains(Creator:) + dd a[rel=author]")
            
            let startDate = DateFormatter.ao3DateFormatter.date(
                from: doc.firstText("dl.series.meta.group dt:contains(Series Begun:) + dd") ?? ""
            ) ?? Date()
            let updateDate = DateFormatter.ao3DateFormatter.date(
                from: doc.firstText("dl.series.meta.group dt:contains(Series Updated:) + dd") ?? ""
            )
            
            let description = extractText(from: try doc.select("dl.series.meta.group dt:contains(Description:) + dd blockquote.userstuff").first())
            let notes = extractText(from: try doc.select("dl.series.meta.group dt:contains(Notes:) + dd blockquote.userstuff").first())
            
            let status: AO3FicStatus = (doc.firstText("dl.series.meta.group dt:contains(Complete:) + dd") == "Yes") ? .completed : .inProgress
            
            let fics = try doc.select("ul.series.work.index.group li.work.blurb").array().compactMap {
                try? parseFicPreview(from: $0)
            }
            
            return AO3Series(
                id: seriesID,
                name: name,
                creators: creators,
                startDate: startDate,
                updateDate: updateDate,
                description: description,
                notes: notes,
                wordCount: doc.firstInt("dl.stats dd.words") ?? 0,
                ficCount: doc.firstInt("dl.stats dd.works") ?? 0,
                bookmarks: doc.firstInt("dl.stats dd.bookmarks") ?? 0,
                status: status,
                fics: fics,
                subscriptionRecordID: try parseSubscriptionID(from: doc)
            )
        }
    }
}
