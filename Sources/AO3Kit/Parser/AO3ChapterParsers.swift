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
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            let rawTitle = try doc.select("div.chapter.preface.group h3.title").first()?.text() ?? "Chapter \(chapterLink.index)"
            var cleanTitle = rawTitle
            if let range = cleanTitle.range(of: "^Chapter \\d+:?\\s*", options: .regularExpression) {
                cleanTitle.removeSubrange(range)
            }
            if cleanTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                cleanTitle = "Chapter \(chapterLink.index)"
            }
            
            let summary = extractText(from: try doc.select("div#summary blockquote.userstuff").first())
            let notes = extractText(from: try doc.select("div#notes blockquote.userstuff").first())
            let endNotes = extractText(from: try doc.select("div#chapter_endnotes blockquote.userstuff, div#work_endnotes blockquote.userstuff").first())
            
            var authorElements = try doc.select("div.chapter.preface.group h3.byline.heading a[rel=author]").array()
            
            if authorElements.isEmpty {
                authorElements = try doc.select("h3.byline.heading a[rel=author]").array()
            }
            
            let authors: [AO3AuthorLink] = try authorElements.compactMap { el in
                let href = try el.attr("href")
                let name = try el.text()
                
                let components = href.components(separatedBy: "/")
                guard components.count >= 3, components[1] == "users" else { return nil }
                
                let id = components[2].removingPercentEncoding ?? components[2]
                let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : id
                
                return AO3AuthorLink(id: id, pseudID: pseudID, displayedName: name)
            }

            
            let contentElement = try doc.select("div.userstuff[role=article]").first()
                              ?? doc.select("div#chapters div.userstuff").first()
            
            let contentHTML = try contentElement?.html() ?? ""
            
            return AO3Chapter(
                id: chapterLink.id,
                index: chapterLink.index,
                title: cleanTitle,
                summary: summary,
                notes: notes,
                endNotes: endNotes,
                authors: authors,
                publicationDate: chapterLink.releaseDate,
                content: contentHTML
            )
        }
    }
    
    
    // MARK: - Navigate Endpoint Parser
    
    /// Parses the HTML from a work's `/navigate` endpoint to extract a complete, sorted list of chapters with their release dates.
    internal static func parseChaptersNavigate(html: String, workID: Int? = nil) -> [AO3ChapterLink] {
        return autoreleasepool {
            do {
                let doc = try SwiftSoup.parse(html)
                
                defer {
                    doc.empty()
                }
                
                // Target the ordered list containing the chapters
                let chapterElements = try doc.select("ol.chapter.index.group li").array()
                var chapters: [AO3ChapterLink] = []
                
                for (index, element) in chapterElements.enumerated() {
                    guard let aTag = try element.select("a").first() else { continue }
                    
                    // Chapter ID
                    let href = try aTag.attr("href")
                    guard let chapterIDString = href.components(separatedBy: "/").last,
                          let chapterID = Int(chapterIDString) else {
                        continue
                    }
                    
                    // Title
                    var cleanTitle = try aTag.text()
                    if let range = cleanTitle.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
                        cleanTitle.removeSubrange(range)
                    }
                    if cleanTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        cleanTitle = "Chapter \(index + 1)"
                    }
                    
                    // Date
                    var releaseDate: Date? = nil
                    if let dateSpan = try element.select("span.datetime").first() {
                        let rawDate = try dateSpan.text()
                        let cleanDateString = rawDate.trimmingCharacters(in: CharacterSet(charactersIn: "() \n"))
                        releaseDate = DateFormatter.ao3DateFormatter.date(from: cleanDateString)
                    }
                    
                    // Link
                    let chapterLink = AO3ChapterLink(
                        id: chapterID,
                        index: index + 1,
                        name: cleanTitle,
                        releaseDate: releaseDate,
                        workID: workID
                    )
                    
                    chapters.append(chapterLink)
                }
                
                return chapters
                
            } catch {
                print("❌ Failed to parse navigate HTML: \(error)")
                return []
            }
        }
    }
    
    
    
    // MARK: - Comments Parser
    
    static func parseComments(html: String) throws -> [AO3ChapterCommentThread] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer { doc.empty() }
            
            guard let root = try doc.select("ol.thread").first() else {
                return []
            }
            
            return try parseCommentThread(root)
        }
    }
    
    private static func parseCommentThread(_ ol: Element) throws -> [AO3ChapterCommentThread] {
        var threads: [AO3ChapterCommentThread] = []
        let listItems = try ol.select("> li.comment").array()
        
        for li in listItems {
            // Parse root comment
            let comment = try parseSingleComment(li)
            
            // Parse replies (Nested threads)
            var replies: [AO3ChapterCommentThread] = []
            
            // direct child <ol.thread> (rare)
            if let nestedOl = try li.select("> ol.thread").first() {
                replies = try parseCommentThread(nestedOl)
            } else {
                // wrapper sibling <li> containing <ol.thread>
                if let sibling = try li.nextElementSibling(),
                   let nestedOl = try sibling.select("> ol.thread").first() {
                    replies = try parseCommentThread(nestedOl)
                }
            }
            
            threads.append(AO3ChapterCommentThread(
                id: comment.id,
                rootComment: comment,
                replies: replies.isEmpty ? nil : replies
            ))
        }
        
        return threads
    }
    
    private static func parseSingleComment(_ li: Element) throws -> AO3ChapterComment {
        // ID
        let rawIDString = try li.attr("id").replacingOccurrences(of: "comment_", with: "")
        let id = Int(rawIDString) ?? 0
        
        let isDeleted = (try? li.select("blockquote.userstuff").isEmpty()) ?? true
        
        // Extract Profile Picture
        var profilePicture: AO3Image? = nil
        if let iconImg = try li.select("div.icon img.icon").first() {
            let src = try iconImg.attr("src")
            let alt = try iconImg.attr("alt")
            
            if !src.isEmpty {
                let fullURL = src.hasPrefix("http") ? src : "https://archiveofourown.org\(src)"
                profilePicture = AO3Image(
                    description: alt.isEmpty ? nil : alt,
                    source: fullURL
                )
            }
        }
        
        // User Data Mapping
        var user: AO3CommenterType? = nil
        let heading = try li.select("h4.heading.byline").first()
        
        if let authorLink = try heading?.select("> a").first() {
            // Registered User
            let href = try authorLink.attr("href")
            let name = try authorLink.text()
            let components = href.components(separatedBy: "/")
            
            let userID = components.count >= 3 ? (components[2].removingPercentEncoding ?? components[2]) : name
            let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
            
            let author = AO3AuthorLink(
                id: userID,
                pseudID: pseudID,
                displayedName: name,
                profilePicture: profilePicture
            )
            user = .registered(link: author)
            
        } else if let guestName = try heading?.select("> span").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines) {
            user = .guest(name: guestName)
        }
        
        var parsedAO3UserID: Int? = nil
        let classAttr = try li.attr("class")
        if let match = classAttr.range(of: #"user-(\d+)"#, options: .regularExpression) {
            parsedAO3UserID = Int(classAttr[match].dropFirst(5))
        }
        
        // Dates & Content
        let postedDate = try parseCommentDate(from: try li.select("span.posted.datetime").first())
        var lastEdited: Date? = nil
        if let editedNode = try li.select("p.edited.datetime").first() {
            lastEdited = try parseCommentDate(from: editedNode)
        }
        
        let contentHTML = isDeleted ? "" : (try li.select("blockquote.userstuff").html())
        
        var parsedChapter: AO3ChapterLink? = nil
        if let parentAnchor = try li.select("span.parent a").first() {
            let href = try parentAnchor.attr("href")
            let name = try parentAnchor.text()
            
            var parsedWorkID: Int? = nil
            var parsedChapterID: Int = 0
            
            let urlComponents = href.split(separator: "/").map(String.init)
            
            if urlComponents.count >= 4, urlComponents[0] == "works", urlComponents[2] == "chapters" {
                parsedWorkID = Int(urlComponents[1])
                parsedChapterID = Int(urlComponents[3]) ?? 0
            }
            
            else if urlComponents.count >= 2, urlComponents[0] == "chapters" {
                parsedChapterID = Int(urlComponents[1]) ?? 0
            }
            
            var parsedIndex = 0
            if let match = name.range(of: #"\d+"#, options: .regularExpression) {
                parsedIndex = Int(name[match]) ?? 0
            }
            
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
        guard let container = container else { return Date() }
        
        let day = try container.select("abbr.day").attr("title")
        let dayShort = try container.select("abbr.day").text()
        let dateNum = try container.select("span.date").text()
        let month = try container.select("abbr.month").attr("title")
        let monthShort = try container.select("abbr.month").text()
        let year = try container.select("span.year").text()
        let time = try container.select("span.time").text()
        let tz = try container.select("abbr.timezone").text()
        
        let full = "\(dayShort.isEmpty ? day : dayShort) \(dateNum) \(monthShort.isEmpty ? month : monthShort) \(year) \(time) \(tz)"
        
        guard let date = DateFormatter.ao3CommentDateFormatter.date(from: full) else {
            return Date()
        }
        return date
    }
}
