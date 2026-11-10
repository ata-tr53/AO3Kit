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
        
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            // Basic Info
            let displayName = try doc.select("h2.title.heading").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Title"
            
            // Authors
            let authorElements = try doc.select("h3.byline.heading a[rel=author]").array()
            let authors: [AO3AuthorLink] = try authorElements.compactMap { el in
                let href = try el.attr("href")
                let name = try el.text()
                
                let components = href.components(separatedBy: "/")
                guard components.count >= 3, components[1] == "users" else { return nil }
                
                let id = components[2].removingPercentEncoding ?? components[2]
                let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : id
                
                return AO3AuthorLink(id: id, pseudID: pseudID, displayedName: name)
            }
            
            // Text Fields (Summary & Notes)
            let summary = extractText(from: try doc.select("div.summary blockquote.userstuff").first())
            let notes = extractText(from: try doc.select("div.notes blockquote.userstuff").first())
            let endNotes = extractText(from: try doc.select("div#work_endnotes blockquote.userstuff").first())
            
            // Tags & Metadata
            let fandoms = try doc.select("dd.fandom.tags a.tag").array().map { try $0.text() }
            let relationships = try doc.select("dd.relationship.tags a.tag").array().map { try $0.text() }
            let characters = try doc.select("dd.character.tags a.tag").array().map { try $0.text() }
            let additionalTags = try doc.select("dd.freeform.tags a.tag").array().map { try $0.text() }
            
            let language = try doc.select("dd.language").first()?.text() ?? "Unknown"
            
            // Ratings, Warnings, and Categories
            let ratingText = try doc.select("dd.rating.tags a.tag").first()?.text() ?? ""
            let contentRating = mapContentRating(ratingText)
            
            let categoryTexts = try doc.select("dd.category.tags a.tag").array().map { try $0.text() }
            let relationshipCategories = categoryTexts.compactMap(mapRelationshipCategory)
            
            let warningTexts = try doc.select("dd.warning.tags a.tag").array().map { try $0.text() }
            let archiveWarnings = warningTexts.compactMap(mapContentWarning)
            
            // Series & Collections
            let series: [AO3SeriesLink] = try doc.select("dd.series span.position a").array().compactMap { el in
                let href = try el.attr("href")
                guard let idString = href.components(separatedBy: "/").last, let id = Int(idString) else { return nil }
                let name = try el.text()
                let parentText = el.parent()?.ownText() ?? ""
                let partIndex = Int(parentText.components(separatedBy: .whitespaces).compactMap { Int($0) }.first ?? 0)
                
                return AO3SeriesLink(id: id, name: name, partIndex: partIndex > 0 ? partIndex : nil)
            }
            
            let collections: [AO3CollectionLink] = try doc.select("dd.collections a").array().compactMap { el in
                let href = try el.attr("href")
                guard let id = href.components(separatedBy: "/").last else { return nil }
                return AO3CollectionLink(id: id.removingPercentEncoding ?? id, displayName: try el.text())
            }
            
            // Stats & Dates
            let publishDateText = try doc.select("dd.published").first()?.text() ?? ""
            let updateDateText = try doc.select("dd.status").first()?.text()
            
            let publishDate = DateFormatter.ao3DateFormatter.date(from: publishDateText) ?? Date()
            let updateDate = updateDateText.flatMap { DateFormatter.ao3DateFormatter.date(from: $0) }
            
            let wordCount = parseInt(try doc.select("dd.words").first()?.text()) ?? 0
            let commentCount = parseInt(try doc.select("dd.comments").first()?.text()) ?? 0
            let kudosCount = parseInt(try doc.select("dd.kudos").first()?.text()) ?? 0
            let bookmarkCount = parseInt(try doc.select("dd.bookmarks").first()?.text()) ?? 0
            let hitCount = parseInt(try doc.select("dd.hits").first()?.text())
            
            // Chapters Setup
            let chaptersText = try doc.select("dd.chapters").first()?.text() ?? "1/1"
            let chaptersSplit = chaptersText.split(separator: "/")
            let currentChapterCount = Int(chaptersSplit.first ?? "1") ?? 1
            let expectedChapterCount = chaptersSplit.count > 1 ? Int(chaptersSplit[1]) : nil
            
            let isCompleted = try doc.select("dt.status").first()?.text() == "Completed:"
            let status: AO3FicStatus = isCompleted ? .completed : (expectedChapterCount == currentChapterCount ? .completed : .inProgress)
            
            var sortedChapters: [AO3ChapterLink] = []
            if let chapterHTML {
                sortedChapters = self.parseChaptersNavigate(html: chapterHTML, workID: workID)
            } else {
                let chapterMap = extractChapters(from: html, forWorkID: workID)
                
                if chapterMap.isEmpty {
                    let chapterID: Int?
                    if case let .chapter(id) = route {
                        chapterID = id
                    } else { chapterID = nil }
                    sortedChapters.append(AO3ChapterLink(id: chapterID ?? 1, index: 1, name: displayName, releaseDate: publishDate))
                } else {
                    let sortedIDs = chapterMap.keys.sorted()
                    for (index, id) in sortedIDs.enumerated() {
                        let name = chapterMap[id] ?? "Chapter \(index + 1)"
                        sortedChapters.append(AO3ChapterLink(id: id, index: index + 1, name: name, releaseDate: nil))
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
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            // Parse main fic authors once
            let mainAuthorElements = try doc.select("div.preface.group h3.byline.heading a[rel=author], h3.byline.heading a[rel=author]").array()
            let mainAuthors: [AO3AuthorLink] = try mainAuthorElements.compactMap { el in
                let href = try el.attr("href")
                let name = try el.text()
                
                let components = href.components(separatedBy: "/")
                guard components.count >= 3, components[1] == "users" else { return nil }
                
                let id = components[2].removingPercentEncoding ?? components[2]
                let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : id
                
                return AO3AuthorLink(id: id, pseudID: pseudID, displayedName: name)
            }
            
            var chapters: [AO3Chapter] = []
            
            // Multi-chapter layout (view_full_work=true)
            let chapterDivs = try doc.select("div#chapters > div.chapter").array()
            
            if !chapterDivs.isEmpty {
                for (index, chapterDiv) in chapterDivs.enumerated() {
                    
                    let titleHeader = try chapterDiv.select("div.chapter.preface.group h3.title").first()
                    
                    // 1. Chapter ID (Extract from the href inside the title)
                    var chapterID: Int? = nil
                    if let aTag = try titleHeader?.select("a").first(),
                       let href = try? aTag.attr("href"),
                       let idString = href.components(separatedBy: "/").last {
                        chapterID = Int(idString)
                    }
                    
                    // 2. Title
                    let rawTitle = try titleHeader?.text() ?? "Chapter \(index + 1)"
                    var cleanTitle = rawTitle
                    if let range = cleanTitle.range(of: "^Chapter \\d+:?\\s*", options: .regularExpression) {
                        cleanTitle.removeSubrange(range)
                    }
                    if cleanTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        cleanTitle = "Chapter \(index + 1)"
                    }
                    
                    // 3. Text Fields
                    let summary = extractText(from: try chapterDiv.select("div#summary blockquote.userstuff").first())
                    let notes = extractText(from: try chapterDiv.select("div#notes blockquote.userstuff").first())
                    let endNotes = extractText(from: try chapterDiv.select("div#chapter_endnotes blockquote.userstuff").first())
                    
                    // 4. Chapter-specific authors with fallback
                    let chapterAuthorElements = try chapterDiv.select("div.chapter.preface.group h3.byline.heading a[rel=author]").array()
                    var chapterAuthors: [AO3AuthorLink] = try chapterAuthorElements.compactMap { el in
                        let href = try el.attr("href")
                        let name = try el.text()
                        
                        let components = href.components(separatedBy: "/")
                        guard components.count >= 3, components[1] == "users" else { return nil }
                        
                        let id = components[2].removingPercentEncoding ?? components[2]
                        let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : id
                        
                        return AO3AuthorLink(id: id, pseudID: pseudID, displayedName: name)
                    }
                    
                    if chapterAuthors.isEmpty {
                        chapterAuthors = mainAuthors
                    }
                    
                    // 5. Content
                    let contentElement = try chapterDiv.select("div.userstuff[role=article]").first()
                                      ?? chapterDiv.select("div.userstuff").first()
                    let contentHTML = try contentElement?.html() ?? ""
                    
                    let chapter = AO3Chapter(
                        id: chapterID, // Now passing the accurately parsed ID
                        index: index + 1,
                        title: cleanTitle,
                        summary: summary,
                        notes: notes,
                        endNotes: endNotes,
                        authors: chapterAuthors,
                        publicationDate: nil,
                        content: contentHTML
                    )
                    
                    chapters.append(chapter)
                }
            } else {
                // Fallback for one-shots
                let title = try doc.select("h2.title.heading").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines) ?? "Chapter 1"
                
                let contentElement = try doc.select("div#chapters div.userstuff").first()
                let contentHTML = try contentElement?.html() ?? ""
                
                let chapter = AO3Chapter(
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
                
                chapters.append(chapter)
            }
            
            return chapters
        }
    }
    
    
    // MARK: - Fic Preview (Blurb) Parser
    
    /// Parses an entire page (like Search Results or Bookmarks) and returns all fic previews.
    static func parseFicPreviews(html: String) throws -> [AO3FicPreview] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            let blurbs = try doc.select("li.work.blurb").array()
            
            return blurbs.compactMap { element in
                do {
                    return try parseFicPreview(from: element)
                } catch {
                    print("⚠️ Failed to parse a fic preview: \(error)")
                    return nil
                }
            }
        }
    }
    
    /// Parses a single `li.work.blurb` element into an AO3FicPreview.
    internal static func parseFicPreview(from element: Element) throws -> AO3FicPreview {
        
        // ID
        var idString = try element.attr("id").replacingOccurrences(of: "work_", with: "")
        
        if idString.hasPrefix("bookmark_") {
            if let href = try element.select("h4.heading a[href^='/works/']").first()?.attr("href"),
               let workID = href.components(separatedBy: "/").last {
                idString = workID
            }
        }
        
        guard let id = Int(idString) else { throw AO3ClientError.invalidData }

        
        // Title & Authors
        let displayName = try element.select("h4.heading a").first()?.text() ?? "Unknown Title"
        
        let authorElements = try element.select("h4.heading a[rel=author]").array()
        let authors: [AO3AuthorLink] = try authorElements.compactMap { el in
            let href = try el.attr("href")
            let name = try el.text()
            
            let components = href.components(separatedBy: "/")
            guard components.count >= 3, components[1] == "users" else { return nil }
            
            let userID = components[2].removingPercentEncoding ?? components[2]
            let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
            
            return AO3AuthorLink(id: userID, pseudID: pseudID, displayedName: name)
        }
        
        let giftedElements = try element.select("h4.heading a[href^='/users/']").array().filter { try $0.attr("rel") != "author" }
        let gifted: [AO3AuthorLink] = try giftedElements.compactMap { el in
            let href = try el.attr("href")
            let name = try el.text()
            let components = href.components(separatedBy: "/")
            guard components.count >= 3 else { return nil }
            let userID = components[2].removingPercentEncoding ?? components[2]
            return AO3AuthorLink(id: userID, pseudID: userID, displayedName: name)
        }
        
        // Fandoms & Tags
        let fandoms = try element.select("h5.fandoms a.tag").array().map { try $0.text() }
        let archiveWarnings = try element.select("li.warnings a.tag").array().compactMap { try mapContentWarning($0.text()) }
        let relationships = try element.select("li.relationships a.tag").array().map { try $0.text() }
        let characters = try element.select("li.characters a.tag").array().map { try $0.text() }
        let additionalTags = try element.select("li.freeforms a.tag").array().map { try $0.text() }
        
        // Series
        let seriesElements = try element.select("ul.series li a").array()
        let series: [AO3SeriesLink] = try seriesElements.compactMap { el in
            let href = try el.attr("href")
            guard let idString = href.components(separatedBy: "/").last, let seriesId = Int(idString) else { return nil }
            
            let parentText = el.parent()?.ownText() ?? ""
            let partIndex = Int(parentText.components(separatedBy: .whitespaces).compactMap { Int($0) }.first ?? 0)
            
            return AO3SeriesLink(id: seriesId, name: try el.text(), partIndex: partIndex > 0 ? partIndex : nil)
        }
        
        // Date & Summary
        let dateText = try element.select("p.datetime").first()?.text() ?? ""
        let latestUpdateDate = DateFormatter.ao3BlurbDateFormatter.date(from: dateText)
        let summary = extractText(from: try element.select("blockquote.summary").first())
        
        // Required Tags
        let ratingText = try element.select("span.rating").attr("title")
        let contentRating = mapContentRating(ratingText)
        
        let categoryText = try element.select("span.category").attr("title")
        let relationshipCategories = categoryText.components(separatedBy: ", ").compactMap { mapRelationshipCategory($0.trimmingCharacters(in: .whitespaces)) }
        
        let statusText = try element.select("span.iswip").attr("title")
        let status: AO3FicStatus = (statusText == "Complete Work") ? .completed : .inProgress
        let isRestricted = try !element.select("img[alt=Restricted]").isEmpty()
        
        // Stats
        let language = try element.select("dd.language").first()?.text() ?? "Unknown"
        let wordCount = parseInt(try element.select("dd.words").first()?.text()) ?? 0
        let commentCount = parseInt(try element.select("dd.comments").first()?.text()) ?? 0
        let kudosCount = parseInt(try element.select("dd.kudos").first()?.text()) ?? 0
        let bookmarkCount = parseInt(try element.select("dd.bookmarks").first()?.text()) ?? 0
        let hitCount = parseInt(try element.select("dd.hits").first()?.text())
        
        // Chapters Setup
        let chaptersText = try element.select("dd.chapters").first()?.text() ?? "1/1"
        let chaptersSplit = chaptersText.split(separator: "/")
        let currentChapterCount = Int(chaptersSplit.first ?? "1") ?? 1
        let expectedChapterCount = chaptersSplit.count > 1 ? Int(chaptersSplit[1]) : nil
        
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
}
