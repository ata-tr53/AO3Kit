//
//  AO3ChapterParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: Chapter Content
    
    static func parseChapter(html: String, chapterLink: AO3ChapterLink) async throws -> AO3Chapter {
        try withDocument(html: html) { doc in
            let cleanTitle = cleanChapterTitle(
                doc.firstText("div.chapter.preface.group h3.title"),
                fallbackIndex: chapterLink.index
            )
            
            let summary = extractText(from: try doc.select("div#summary blockquote.userstuff").first())
            let notes = extractText(from: try doc.select("div#notes blockquote.userstuff").first())
            let endNotes = extractText(from: try doc.select("div#chapter_endnotes blockquote.userstuff, div#work_endnotes blockquote.userstuff").first())
            
            var authors = parseAuthorLinks(in: doc, selector: "div.chapter.preface.group h3.byline.heading a[rel=author]")
            if authors.isEmpty {
                authors = parseAuthorLinks(in: doc, selector: "h3.byline.heading a[rel=author]")
            }
            
            let contentElement = try doc.select("div.userstuff[role=article]").first()
                              ?? doc.select("div#chapters div.userstuff").first()
            
            return AO3Chapter(
                id: chapterLink.id,
                index: chapterLink.index,
                title: cleanTitle,
                summary: summary,
                notes: notes,
                endNotes: endNotes,
                authors: authors,
                publicationDate: chapterLink.releaseDate,
                content: try contentElement?.html() ?? ""
            )
        }
    }
    
    // MARK: - Navigate Endpoint Parser
    
    internal static func parseChaptersNavigate(html: String, workID: Int? = nil) -> [AO3ChapterLink] {
        (try? withDocument(html: html) { doc in
            let chapterElements = try doc.select("ol.chapter.index.group li").array()
            
            return chapterElements.enumerated().compactMap { index, element in
                guard let href = element.firstAttr("a", "href"),
                      let chapterIDString = href.components(separatedBy: "/").last,
                      let chapterID = Int(chapterIDString) else {
                    return nil
                }
                
                let cleanTitle = cleanChapterTitle(element.firstText("a"), fallbackIndex: index + 1)
                let cleanDateString = element.firstText("span.datetime")?.trimmingCharacters(in: CharacterSet(charactersIn: "() \n")) ?? ""
                let releaseDate = DateFormatter.ao3DateFormatter.date(from: cleanDateString)
                
                return AO3ChapterLink(
                    id: chapterID,
                    index: index + 1,
                    name: cleanTitle,
                    releaseDate: releaseDate,
                    workID: workID
                )
            }
        }) ?? []
    }
    
    // MARK: - Comments Parser
    
    static func parseComments(html: String) throws -> [AO3ChapterCommentThread] {
        try withDocument(html: html) { doc in
            guard let root = try doc.select("ol.thread").first() else { return [] }
            return try parseCommentThread(root)
        }
    }
    
    private static func parseCommentThread(_ ol: Element) throws -> [AO3ChapterCommentThread] {
        let listItems = try ol.select("> li.comment").array()
        
        return try listItems.map { li in
            let comment = try parseSingleComment(li)
            var replies: [AO3ChapterCommentThread] = []
            
            if let nestedOl = try li.select("> ol.thread").first() {
                replies = try parseCommentThread(nestedOl)
            } else if let sibling = try li.nextElementSibling(),
                      let nestedOl = try sibling.select("> ol.thread").first() {
                replies = try parseCommentThread(nestedOl)
            }
            
            return AO3ChapterCommentThread(
                id: comment.id,
                rootComment: comment,
                replies: replies.isEmpty ? nil : replies
            )
        }
    }
    
    private static func parseSingleComment(_ li: Element) throws -> AO3ChapterComment {
        let id = Int(try li.attr("id").replacingOccurrences(of: "comment_", with: "")) ?? 0
        let isDeleted = (try? li.select("blockquote.userstuff").isEmpty()) ?? true
        let profilePicture = parseImage(from: try li.select("div.icon img.icon").first())
        
        var user: AO3CommenterType? = nil
        let heading = try li.select("h4.heading.byline").first()
        
        if let author = parseAuthorLink(from: try heading?.select("> a").first(), profilePicture: profilePicture) {
            user = .registered(link: author)
        } else if let guestName = heading?.firstText("> span") {
            user = .guest(name: guestName)
        }
        
        var parsedAO3UserID: Int? = nil
        let classAttr = try li.attr("class")
        if let match = classAttr.range(of: #"user-(\d+)"#, options: .regularExpression) {
            parsedAO3UserID = Int(classAttr[match].dropFirst(5))
        }
        
        let postedDate = try parseCommentDate(from: try li.select("span.posted.datetime").first())
        let lastEdited = try li.select("p.edited.datetime").first().map { try parseCommentDate(from: $0) }
        let contentHTML = isDeleted ? "" : (try li.select("blockquote.userstuff").html())
        
        var parsedChapter: AO3ChapterLink? = nil
        if let parentAnchor = try li.select("span.parent a").first() {
            let href = try parentAnchor.attr("href")
            let name = try parentAnchor.text()
            let urlComponents = href.split(separator: "/").map(String.init)
            
            var parsedWorkID: Int? = nil
            var parsedChapterID = 0
            
            if urlComponents.count >= 4, urlComponents[0] == "works", urlComponents[2] == "chapters" {
                parsedWorkID = Int(urlComponents[1])
                parsedChapterID = Int(urlComponents[3]) ?? 0
            } else if urlComponents.count >= 2, urlComponents[0] == "chapters" {
                parsedChapterID = Int(urlComponents[1]) ?? 0
            }
            
            let parsedIndex = name.range(of: #"\d+"#, options: .regularExpression).flatMap { Int(name[$0]) } ?? 0
            
            if parsedChapterID != 0 {
                parsedChapter = AO3ChapterLink(
                    id: parsedChapterID,
                    index: parsedIndex,
                    name: name,
                    releaseDate: nil,
                    workID: parsedWorkID
                )
            }
        }
        
        return AO3ChapterComment(
            id: id,
            user: user,
            ao3userID: parsedAO3UserID,
            postDate: postedDate,
            lastEdited: lastEdited,
            contentHTML: contentHTML,
            chapter: parsedChapter,
            isDeleted: isDeleted
        )
    }
    
    private static func parseCommentDate(from container: Element?) throws -> Date {
        guard let container else { return Date() }
        
        let day = container.firstText("abbr.day") ?? container.firstAttr("abbr.day", "title") ?? ""
        let dateNum = container.firstText("span.date") ?? ""
        let month = container.firstText("abbr.month") ?? container.firstAttr("abbr.month", "title") ?? ""
        let year = container.firstText("span.year") ?? ""
        let time = container.firstText("span.time") ?? ""
        let tz = container.firstText("abbr.timezone") ?? ""
        
        let full = "\(day) \(dateNum) \(month) \(year) \(time) \(tz)"
        return DateFormatter.ao3CommentDateFormatter.date(from: full) ?? Date()
    }
}
