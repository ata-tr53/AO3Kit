//
//  AO3SearchParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - Tag Search Parser
    
    static func parseTagSearchResults(html: String) throws -> [AO3TagSearchResult] {
        try parseElements(html: html, selector: "ol.tag.index.group > li") { element in
            guard let span = try element.select("span").first(),
                  let name = span.firstText("a.tag") else {
                return nil
            }
            
            let isCanonical = span.hasClass("canonical")
            let fullText = (try? span.text()) ?? ""
            
            // Format: "Fandom: Tag Name (123)"
            let prefix = fullText.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces) ?? ""
            let type = AO3TagSearchFilter.TagType(rawValue: prefix)
            
            var usesCount = 0
            if let openParen = fullText.range(of: "(", options: .backwards)?.upperBound,
               let closeParen = fullText[openParen...].firstIndex(of: ")") {
                usesCount = parseInt(String(fullText[openParen..<closeParen])) ?? 0
            }
            
            return AO3TagSearchResult(
                name: name,
                type: type,
                isCanonical: isCanonical,
                usesCount: usesCount
            )
        }
    }
    
    // MARK: - People Search Parser
    
    static func parsePeopleSearchResults(html: String) throws -> [AO3PersonSearchResult] {
        try parseElements(html: html, selector: "ol.pseud.index.group > li.user.pseud") { element in
            let icon = parseImage(from: try element.select("div.icon img").first())
            guard let authorLink = parseAuthorLink(
                from: try element.select("h4.heading a").first(),
                profilePicture: icon
            ) else {
                return nil
            }
            
            let worksText = element.firstText("h5.heading a[href$='/works']")?.replacingOccurrences(of: " works", with: "").replacingOccurrences(of: " work", with: "")
            let bookmarksText = element.firstText("h5.heading a[href$='/bookmarks']")?.replacingOccurrences(of: " bookmarks", with: "").replacingOccurrences(of: " bookmark", with: "")
            
            return AO3PersonSearchResult(
                author: authorLink,
                workCount: parseInt(worksText) ?? 0,
                bookmarkCount: parseInt(bookmarksText) ?? 0
            )
        }
    }
}
