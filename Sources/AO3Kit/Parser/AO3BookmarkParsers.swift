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
        try parseElements(html: html, selector: "li.bookmark.blurb", transform: parseBookmark)
    }
    
    internal static func parseBookmark(from element: Element) throws -> AO3FicBookmark {
        let idString = try element.attr("id").replacingOccurrences(of: "bookmark_", with: "")
        guard let id = Int(idString) else { throw AO3ClientError.invalidData }
        
        let isDeleted = try !element.select("p.message:contains(deleted)").isEmpty()
        let ficPreview: AO3FicPreview? = isDeleted ? nil : try parseFicPreview(from: element)
        
        let userModule = try element.select("div.user.module.group").first()
        let user = parseAuthorLink(from: try userModule?.select("h5.byline.heading a").first())
            ?? AO3AuthorLink(id: "Unknown", pseudID: "Unknown", displayedName: "Unknown")
        
        let bookmarkDate = DateFormatter.ao3BlurbDateFormatter.date(from: userModule?.firstText("p.datetime") ?? "") ?? Date()
        let notes = extractText(from: try userModule?.select("blockquote.notes").first())
        let status = try parseBookmarkStatuses(in: element)
        let customTags = userModule?.texts("ul.meta.tags a.tag") ?? []
        let collections = userModule.map { parseCollectionLinks(in: $0, selector: "ul.meta.collections a") } ?? []
        
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
        try parseElements(html: html, selector: "li.user.short.blurb") { element in
            let user = parseAuthorLink(from: try element.select("h5.byline.heading a").first())
                ?? AO3AuthorLink(id: "Unknown", pseudID: "Unknown", displayedName: "Unknown")
            
            let bookmarkDate = DateFormatter.ao3BlurbDateFormatter.date(from: element.firstText("p.datetime") ?? "") ?? Date()
            let notes = extractText(from: try element.select("blockquote.userstuff").first())
            let status = try parseBookmarkStatuses(in: element)
            let collections = parseCollectionLinks(in: element, selector: "h6:contains(Bookmark Collections:) + ul.meta a")
            
            return AO3BookmarkPreview(
                user: user,
                bookmarkDate: bookmarkDate,
                status: status,
                collections: collections,
                notes: notes
            )
        }
    }
    
    private static func parseBookmarkStatuses(in element: Element) throws -> [AO3BookmarkStatus] {
        var status: [AO3BookmarkStatus] = []
        for span in try element.select("p.status span").array() {
            let className = try span.className()
            if className.contains("public") { status.append(.public) }
            else if className.contains("private") { status.append(.private) }
            else if className.contains("rec") { status.append(.rec) }
            else if className.contains("hidden") { status.append(.hidden) }
        }
        return status.isEmpty ? [.public] : status
    }

    // MARK: - Single Bookmark & Form Context Parsers

    static func parseSingleBookmark(html: String) throws -> AO3FicBookmark {
        let bookmarks = try parseBookmarks(html: html)
        guard let first = bookmarks.first else {
            throw AO3ClientError.noDataFound
        }
        return first
    }

    internal struct AO3BookmarkFormContext: Sendable {
        let csrfToken: String
        let actionPath: String
        let isEditing: Bool
        let pseudMap: [String: Int]
        let defaultPseudID: Int
    }

    internal static func parseBookmarkFormContext(from html: String) throws -> AO3BookmarkFormContext {
        let csrfToken = try parseCSRFToken(from: html)

        return try withDocument(html: html) { doc in
            guard let form = try doc.select("form#bookmark-form, form.new_bookmark, form.edit_bookmark, form[action*='/bookmarks']").first(),
                  let actionPath = try? form.attr("action"),
                  !actionPath.isEmpty else {
                throw AO3ClientError.invalidData
            }

            let methodInput = form.firstAttr("input[name='_method']", "value")?.lowercased()
            let isEditing = methodInput == "patch" || methodInput == "put"

            var pseudMap: [String: Int] = [:]
            var defaultPseudID: Int? = nil

            let options = try form.select("select[name='bookmark[pseud_id]'] option").array()
            for option in options {
                let name = (try? option.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                if let id = Int((try? option.attr("value")) ?? "") {
                    pseudMap[name] = id
                    if option.hasAttr("selected") || defaultPseudID == nil {
                        defaultPseudID = id
                    }
                }
            }

            if defaultPseudID == nil,
               let hiddenVal = form.firstAttr("input[name='bookmark[pseud_id]']", "value"),
               let hiddenID = Int(hiddenVal) {
                defaultPseudID = hiddenID
            }

            guard let resolvedDefaultPseudID = defaultPseudID else {
                throw AO3ClientError.pseudNotFound
            }

            return AO3BookmarkFormContext(
                csrfToken: csrfToken,
                actionPath: actionPath,
                isEditing: isEditing,
                pseudMap: pseudMap,
                defaultPseudID: resolvedDefaultPseudID
            )
        }
    }
}
