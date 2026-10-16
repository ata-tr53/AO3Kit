//
//  AO3BookmarkParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - Bookmark Previews Parser
    
    static func parseBookmarks(html: String) throws -> [AO3FicBookmark] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            let blurbs = try doc.select("li.bookmark.blurb").array()
            
            return blurbs.compactMap { element in
                do {
                    return try parseBookmark(from: element)
                } catch {
                    print("⚠️ Failed to parse a bookmark: \(error)")
                    return nil
                }
            }
        }
    }
    
    internal static func parseBookmark(from element: Element) throws -> AO3FicBookmark {
        // Bookmark ID
        let idString = try element.attr("id").replacingOccurrences(of: "bookmark_", with: "")
        guard let id = Int(idString) else { throw AO3ClientError.invalidData }
        
        // Check for Deleted Work
        let isDeleted = try !element.select("p.message:contains(deleted)").isEmpty()
        let ficPreview: AO3FicPreview? = isDeleted ? nil : try parseFicPreview(from: element)
        
        // User Data (The Bookmarker)
        let userModule = try element.select("div.user.module.group").first()
        let userLinkElement = try userModule?.select("h5.byline.heading a").first()
        
        let userName = try userLinkElement?.text() ?? "Unknown"
        let href = try userLinkElement?.attr("href") ?? ""
        let components = href.components(separatedBy: "/")
        
        let userID = components.count >= 3 ? (components[2].removingPercentEncoding ?? components[2]) : userName
        let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
        
        let user = AO3AuthorLink(id: userID, pseudID: pseudID, displayedName: userName)
        
        // Bookmark Date
        let dateText = try userModule?.select("p.datetime").first()?.text() ?? ""
        let bookmarkDate = DateFormatter.ao3BlurbDateFormatter.date(from: dateText) ?? Date()
        
        // Bookmark Notes
        let notes = extractText(from: try userModule?.select("blockquote.notes").first())
        
        // Status (Public, Private, Rec)
        var status: [AO3BookmarkStatus] = []
        let statusElements = try element.select("p.status span").array()
        
        for span in statusElements {
            let className = try span.className()
            if className.contains("public") { status.append(.public) }
            else if className.contains("private") { status.append(.private) }
            else if className.contains("rec") { status.append(.rec) }
            else if className.contains("hidden") { status.append(.hidden) }
        }
        
        if status.isEmpty { status.append(.public) } // Safe fallback
        
        // Custom Tags & Collections (Bookmarks can have custom tags added by the user)
        let customTags = try userModule?.select("ul.meta.tags a.tag").array().map { try $0.text() } ?? []
        
        let collectionElements = try userModule?.select("ul.meta.collections a").array() ?? []
        let collections: [AO3CollectionLink] = try collectionElements.compactMap { el in
            let colHref = try el.attr("href")
            guard let colID = colHref.components(separatedBy: "/").last else { return nil }
            return AO3CollectionLink(id: colID.removingPercentEncoding ?? colID, name: try el.text())
        }
        
        return AO3FicBookmark(
            id: id,
            ficPreview: ficPreview,
            user: user,
            tags: customTags,
            bookmarkDate: bookmarkDate,
            status: status,
            collections: collections,
            notes: notes
        )
    }
    
    // MARK: - Work Bookmarks Parser
    
    static func parseWorkBookmarks(html: String) throws -> [AO3BookmarkPreview] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            let blurbs = try doc.select("li.user.short.blurb").array()
            
            return blurbs.compactMap { element in
                do {
                    // User
                    let userLinkElement = try element.select("h5.byline.heading a").first()
                    let userName = try userLinkElement?.text() ?? "Unknown"
                    let href = try userLinkElement?.attr("href") ?? ""
                    let components = href.components(separatedBy: "/")
                    
                    let userID = components.count >= 3 ? (components[2].removingPercentEncoding ?? components[2]) : userName
                    let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
                    
                    let user = AO3AuthorLink(id: userID, pseudID: pseudID, displayedName: userName)
                    
                    // Date
                    let dateText = try element.select("p.datetime").first()?.text() ?? ""
                    let bookmarkDate = DateFormatter.ao3BlurbDateFormatter.date(from: dateText) ?? Date()
                    
                    // Notes
                    let notes = extractText(from: try element.select("blockquote.userstuff").first())
                    
                    // Status
                    var status: [AO3BookmarkStatus] = []
                    let statusElements = try element.select("p.status span").array()
                    for span in statusElements {
                        let className = try span.className()
                        if className.contains("public") { status.append(.public) }
                        else if className.contains("private") { status.append(.private) }
                        else if className.contains("rec") { status.append(.rec) }
                        else if className.contains("hidden") { status.append(.hidden) }
                    }
                    if status.isEmpty { status.append(.public) }
                    
                    // Collections
                    let collectionElements = try element.select("h6:contains(Bookmark Collections:) + ul.meta a").array()
                    let collections: [AO3CollectionLink] = try collectionElements.compactMap { el in
                        let colHref = try el.attr("href")
                        guard let colID = colHref.components(separatedBy: "/").last else { return nil }
                        return AO3CollectionLink(id: colID.removingPercentEncoding ?? colID, name: try el.text())
                    }
                    
                    return AO3BookmarkPreview(
                        user: user,
                        bookmarkDate: bookmarkDate,
                        status: status,
                        collections: collections,
                        notes: notes
                    )
                    
                } catch {
                    print("⚠️ Failed to parse a short bookmark: \(error)")
                    return nil
                }
            }
        }
    }
}
