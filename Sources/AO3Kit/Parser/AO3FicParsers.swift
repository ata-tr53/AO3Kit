//
//  AO3FicParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    // MARK: Fic Metadata
    
    static func parseFicMetadata(html: String, chapterHTML: String? = nil, work: AO3Endpoint) async throws -> AO3FicMetadata {
        guard case let AO3Endpoint.work(workID, route) = work else {
            throw AO3ClientError.invalidEndpoint
        }
        
        return try withDocument(html: html) { doc in
            let displayName = doc.firstText("h2.title.heading") ?? "Unknown Title"
            let authors = parseAuthorLinks(in: doc, selector: "h3.byline.heading a[rel=author]")
            
            let summary = extractText(from: try doc.select("div.summary blockquote.userstuff").first())
            let notes = extractText(from: try doc.select("div.notes blockquote.userstuff").first())
            let endNotes = extractText(from: try doc.select("div#work_endnotes blockquote.userstuff").first())
            
            let fandoms = doc.texts("dd.fandom.tags a.tag")
            let relationships = doc.texts("dd.relationship.tags a.tag")
            let characters = doc.texts("dd.character.tags a.tag")
            let additionalTags = doc.texts("dd.freeform.tags a.tag")
            let language = doc.firstText("dd.language") ?? "Unknown"
            
            let contentRating = mapContentRating(doc.firstText("dd.rating.tags a.tag") ?? "")
            let relationshipCategories = doc.texts("dd.category.tags a.tag").compactMap(mapRelationshipCategory)
            let archiveWarnings = doc.texts("dd.warning.tags a.tag").compactMap(mapContentWarning)
            
            let series = parseSeriesLinks(in: doc, selector: "dd.series span.position a")
            let collections = parseCollectionLinks(in: doc, selector: "dd.collections a")
            
            let publishDate = DateFormatter.ao3DateFormatter.date(from: doc.firstText("dd.published") ?? "") ?? Date()
            let updateDate = doc.firstText("dd.status").flatMap { DateFormatter.ao3DateFormatter.date(from: $0) }
            
            let wordCount = doc.firstInt("dd.words") ?? 0
            let commentCount = doc.firstInt("dd.comments") ?? 0
            let kudosCount = doc.firstInt("dd.kudos") ?? 0
            let bookmarkCount = doc.firstInt("dd.bookmarks") ?? 0
            let hitCount = doc.firstInt("dd.hits")
            
            let (currentChapterCount, expectedChapterCount) = parseChapterCounts(from: doc.firstText("dd.chapters"))
            let isCompleted = doc.firstText("dt.status") == "Completed:"
            let status: AO3FicStatus = (isCompleted || expectedChapterCount == currentChapterCount) ? .completed : .inProgress
            
            var sortedChapters: [AO3ChapterLink] = []
            if let chapterHTML {
                sortedChapters = parseChaptersNavigate(html: chapterHTML, workID: workID)
            } else {
                let chapterMap = extractChapters(from: html, forWorkID: workID)
                if chapterMap.isEmpty {
                    let chapterID: Int? = if case let .chapter(id) = route { id } else { nil }
                    sortedChapters.append(AO3ChapterLink(id: chapterID ?? 1, index: 1, name: displayName, releaseDate: publishDate))
                } else {
                    for (index, id) in chapterMap.keys.sorted().enumerated() {
                        sortedChapters.append(AO3ChapterLink(id: id, index: index + 1, name: chapterMap[id] ?? "Chapter \(index + 1)", releaseDate: nil))
                    }
                }
            }
            
            let workSkinCSS = extractWorkSkinCSS(from: doc)
            let isRestricted = try !doc.select("img[title=Restricted]").isEmpty()
            let subscriptionRecordID = try parseSubscriptionID(from: doc)
            
            return AO3FicMetadata(
                id: workID,
                displayName: displayName,
                summary: summary,
                notes: notes,
                endNotes: endNotes,
                authors: authors,
                fandoms: fandoms,
                relationships: relationships,
                characters: characters,
                additionalTags: additionalTags,
                series: series,
                collections: collections,
                chapters: sortedChapters,
                publishDate: publishDate,
                updateDate: updateDate,
                wordCount: wordCount,
                currentChapterCount: currentChapterCount,
                expectedChapterCount: expectedChapterCount,
                isRestricted: isRestricted,
                language: language,
                status: status,
                contentRating: contentRating,
                relationshipCategories: relationshipCategories,
                archiveWarnings: archiveWarnings,
                commentCount: commentCount,
                kudosCount: kudosCount,
                bookmarkCount: bookmarkCount,
                hitCount: hitCount,
                workSkinCSS: workSkinCSS,
                subscriptionRecordID: subscriptionRecordID
            )
        }
    }
    
    // MARK: - Full Work Parser
    
    static func parseFullWorkChapters(html: String) throws -> [AO3Chapter] {
        try withDocument(html: html) { doc in
            let mainAuthors = parseAuthorLinks(in: doc, selector: "div.preface.group h3.byline.heading a[rel=author], h3.byline.heading a[rel=author]")
            let chapterDivs = try doc.select("div#chapters > div.chapter").array()
            
            guard !chapterDivs.isEmpty else {
                let title = doc.firstText("h2.title.heading") ?? "Chapter 1"
                let contentHTML = try doc.select("div#chapters div.userstuff").first()?.html() ?? ""
                return [
                    AO3Chapter(
                        id: nil,
                        index: 1,
                        title: title,
                        summary: nil,
                        notes: nil,
                        endNotes: nil,
                        authors: mainAuthors,
                        publicationDate: nil,
                        content: contentHTML
                    )
                ]
            }
            
            return try chapterDivs.enumerated().map { index, chapterDiv in
                let titleHeader = try chapterDiv.select("div.chapter.preface.group h3.title").first()
                let chapterID = titleHeader?.firstAttr("a", "href")?.components(separatedBy: "/").last.flatMap(Int.init)
                let cleanTitle = cleanChapterTitle(try titleHeader?.text(), fallbackIndex: index + 1)
                
                let summary = extractText(from: try chapterDiv.select("div#summary blockquote.userstuff").first())
                let notes = extractText(from: try chapterDiv.select("div#notes blockquote.userstuff").first())
                let endNotes = extractText(from: try chapterDiv.select("div#chapter_endnotes blockquote.userstuff").first())
                
                let chapterAuthors = parseAuthorLinks(in: chapterDiv, selector: "div.chapter.preface.group h3.byline.heading a[rel=author]")
                let contentElement = try chapterDiv.select("div.userstuff[role=article]").first()
                                  ?? chapterDiv.select("div.userstuff").first()
                
                return AO3Chapter(
                    id: chapterID,
                    index: index + 1,
                    title: cleanTitle,
                    summary: summary,
                    notes: notes,
                    endNotes: endNotes,
                    authors: chapterAuthors.isEmpty ? mainAuthors : chapterAuthors,
                    publicationDate: nil,
                    content: try contentElement?.html() ?? ""
                )
            }
        }
    }
    
    
    // MARK: - Fic Preview (Blurb) Parser
    
    /// Parses an entire page (like Search Results or Bookmarks) and returns all fic previews.
    static func parseFicPreviews(html: String) throws -> [AO3FicPreview] {
        try parseElements(html: html, selector: "li.work.blurb", transform: parseFicPreview)
    }
    
    internal static func parseFicPreview(from element: Element) throws -> AO3FicPreview {
        
        var idString = try element.attr("id").replacingOccurrences(of: "work_", with: "")
        if idString.hasPrefix("bookmark_"),
           let workID = element.firstAttr("h4.heading a[href^='/works/']", "href")?.components(separatedBy: "/").last {
            idString = workID
        }
        guard let id = Int(idString) else { throw AO3ClientError.invalidData }
        
        let displayName = element.firstText("h4.heading a") ?? "Unknown Title"
        let authors = parseAuthorLinks(in: element, selector: "h4.heading a[rel=author]")
        let gifted = parseAuthorLinks(in: element, selector: "h4.heading a[href^='/users/']:not([rel=author])")
        
        let fandoms = element.texts("h5.fandoms a.tag")
        let archiveWarnings = element.texts("li.warnings a.tag").compactMap(mapContentWarning)
        let relationships = element.texts("li.relationships a.tag")
        let characters = element.texts("li.characters a.tag")
        let additionalTags = element.texts("li.freeforms a.tag")
        let series = parseSeriesLinks(in: element, selector: "ul.series li a")
        
        let latestUpdateDate = DateFormatter.ao3BlurbDateFormatter.date(from: element.firstText("p.datetime") ?? "")
        let summary = extractText(from: try element.select("blockquote.summary").first())
        
        let contentRating = mapContentRating(element.firstAttr("span.rating", "title") ?? "")
        let categoryText = element.firstAttr("span.category", "title") ?? ""
        let relationshipCategories = categoryText.components(separatedBy: ", ").compactMap {
            mapRelationshipCategory($0.trimmingCharacters(in: .whitespaces))
        }
        
        let status: AO3FicStatus = (element.firstAttr("span.iswip", "title") == "Complete Work") ? .completed : .inProgress
        let isRestricted = try !element.select("img[alt=Restricted]").isEmpty()
        
        let language = element.firstText("dd.language") ?? "Unknown"
        let wordCount = element.firstInt("dd.words") ?? 0
        let commentCount = element.firstInt("dd.comments") ?? 0
        let kudosCount = element.firstInt("dd.kudos") ?? 0
        let bookmarkCount = element.firstInt("dd.bookmarks") ?? 0
        let hitCount = element.firstInt("dd.hits")
        
        let (currentChapterCount, expectedChapterCount) = parseChapterCounts(from: element.firstText("dd.chapters"))
        
        return AO3FicPreview(
            id: id,
            displayName: displayName,
            summary: summary,
            authors: authors,
            gifted: gifted,
            fandoms: fandoms,
            relationships: relationships,
            characters: characters,
            additionalTags: additionalTags,
            series: series,
            latestUpdateDate: latestUpdateDate,
            wordCount: wordCount,
            currentChapterCount: currentChapterCount,
            expectedChapterCount: expectedChapterCount,
            isRestricted: isRestricted,
            language: language,
            status: status,
            contentRating: contentRating,
            relationshipCategories: relationshipCategories,
            archiveWarnings: archiveWarnings,
            commentCount: commentCount,
            kudosCount: kudosCount,
            bookmarkCount: bookmarkCount,
            hitCount: hitCount
        )
    }
    
    private static func parseChapterCounts(from chaptersText: String?) -> (current: Int, expected: Int?) {
        let parts = (chaptersText ?? "1/1").split(separator: "/")
        let current = Int(parts.first ?? "1") ?? 1
        let expected = parts.count > 1 ? Int(parts[1]) : nil
        return (current, expected)
    }
}
