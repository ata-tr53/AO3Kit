//
//  AO3Parser.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import SwiftSoup
import Foundation

public struct AO3Parser {
    
    /// Parses an HTML string into a SwiftSoup Document, runs `body`, and guarantees `doc.empty()` inside an autoreleasepool.
    internal static func withDocument<T>(html: String, _ body: (Document) throws -> T) throws -> T {
        try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            defer { doc.empty() }
            return try body(doc)
        }
    }
    
    /// Selects all matching elements in `html` and maps each element with `transform`, skipping individual failures.
    internal static func parseElements<T>(
        html: String,
        selector: String,
        transform: (Element) throws -> T?
    ) throws -> [T] {
        try withDocument(html: html) { doc in
            try doc.select(selector).array().compactMap { element in
                try? transform(element)
            }
        }
    }
    
    // MARK: Shared Component Extractors
    
    internal static func parseImage(from imgElement: Element?) -> AO3Image? {
        guard let imgElement,
              let src = try? imgElement.attr("src"),
              !src.isEmpty else { return nil }
        
        let alt = (try? imgElement.attr("alt")) ?? ""
        let fullURL = src.hasPrefix("http") ? src : "https://archiveofourown.org\(src)"
        return AO3Image(description: alt.isEmpty ? nil : alt, source: fullURL)
    }
    
    static func parseAuthorLink(from linkElement: Element?, profilePicture: AO3Image? = nil) -> AO3AuthorLink? {
        guard let linkElement,
              let href = try? linkElement.attr("href"),
              let name = try? linkElement.text(),
              !name.isEmpty else { return nil }
        
        let components = href.components(separatedBy: "/")
        guard components.count >= 3, components[1] == "users" else { return nil }
        
        let userID = components[2].removingPercentEncoding ?? components[2]
        let pseudID = (components.count >= 5 && components[3] == "pseuds")
            ? (components[4].removingPercentEncoding ?? components[4])
            : userID
        
        return AO3AuthorLink(
            id: userID,
            pseudID: pseudID,
            displayedName: name,
            profilePicture: profilePicture
        )
    }
    
    static func parseAuthorLinks(in container: Element, selector: String = "a[rel=author]") -> [AO3AuthorLink] {
        guard let elements = try? container.select(selector).array() else { return [] }
        return elements.compactMap { parseAuthorLink(from: $0) }
    }
    
    static func parseCollectionLinks(in container: Element, selector: String) -> [AO3CollectionLink] {
        guard let elements = try? container.select(selector).array() else { return [] }
        return elements.compactMap { el in
            guard let href = try? el.attr("href"),
                  let rawID = href.components(separatedBy: "/").last,
                  !rawID.isEmpty,
                  let name = try? el.text() else { return nil }
            return AO3CollectionLink(id: rawID.removingPercentEncoding ?? rawID, displayName: name)
        }
    }
    
    static func parseSeriesLinks(in container: Element, selector: String) -> [AO3SeriesLink] {
        guard let elements = try? container.select(selector).array() else { return [] }
        return elements.compactMap { el in
            guard let href = try? el.attr("href"),
                  let idString = href.components(separatedBy: "/").last,
                  let seriesID = Int(idString),
                  let name = try? el.text() else { return nil }
            
            let parentText = el.parent()?.ownText() ?? ""
            let partIndex = parentText.components(separatedBy: .whitespaces).compactMap(Int.init).first ?? 0
            return AO3SeriesLink(id: seriesID, name: name, partIndex: partIndex > 0 ? partIndex : nil)
        }
    }
    
    static func cleanChapterTitle(_ rawTitle: String?, fallbackIndex: Int) -> String {
        guard var title = rawTitle else { return "Chapter \(fallbackIndex)" }
        if let range = title.range(of: #"^(Chapter \d+:?|\d+\.)\s*"#, options: .regularExpression) {
            title.removeSubrange(range)
        }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Chapter \(fallbackIndex)" : trimmed
    }
    
    // MARK: - Pagination Parser
    
    internal static func parsePagination(html: String) throws -> (currentPage: Int, totalPages: Int) {
        try withDocument(html: html) { doc in
            guard let paginationList = try doc.select("ol.pagination").first() else {
                return (1, 1)
            }
            
            let currentPage = paginationList.firstInt(".current") ?? 1
            let pageNumbers = paginationList.texts("li a[href*='page=']").compactMap(Int.init)
            let maxPage = max(currentPage, pageNumbers.max() ?? currentPage)
            
            return (currentPage, maxPage)
        }
    }
    
    
    // MARK: - HTML Extraction Helpers
    
    internal static func extractText(from element: Element?) -> String? {
        guard let element = element else { return nil }
        let paragraphs = try? element.select("p").array().compactMap { try? $0.text() }
        if let paragraphs = paragraphs, !paragraphs.isEmpty {
            return paragraphs.joined(separator: "\n\n")
        }
        return try? element.text()
    }
    
    internal static func parseInt(_ string: String?) -> Int? {
        guard let string = string else { return nil }
        let cleaned = string.replacingOccurrences(of: ",", with: "")
        return Int(cleaned)
    }
    
    // MARK: - Enum Mapping Helpers
    
    internal static func mapContentRating(_ text: String) -> AO3ContentRating {
        switch text {
        case "General Audiences": return .generalAudiences
        case "Teen And Up Audiences": return .teenAndUpAudiences
        case "Mature": return .mature
        case "Explicit": return .explicit
        default: return .notGiven
        }
    }
    
    internal static func mapRelationshipCategory(_ text: String) -> AO3RelationshipCategory? {
        switch text {
        case "F/F": return .fxf
        case "F/M": return .fxm
        case "Gen": return .gen
        case "M/M": return .mxm
        case "Multi": return .multi
        case "Other": return .other
        default: return nil
        }
    }
    
    internal static func mapContentWarning(_ text: String) -> AO3ContentWarning? {
        switch text {
        case "Graphic Depictions Of Violence": return .graphic
        case "Major Character Death": return .majorDeath
        case "Rape/Non-Con": return .nonCon
        case "Underage": return .underage
        case "Creator Chose Not To Use Archive Warnings": return .noArchiveWarnings
        case "No Archive Warnings Apply": return .noWarningsApply
        default: return nil
        }
    }
    
    // MARK: - Work Skin Extraction
    
    static func extractWorkSkinCSS(from doc: Document) -> String? {
        do {
            let styles = try doc.select("style").array()
            
            for style in styles {
                let css = style.data()
                
                if css.contains("#workskin") {
                    return css
                }
            }
        } catch {
            print("⚠️ Failed to extract work skin CSS: \(error)")
        }
        return nil
    }
    
    // MARK: - Extract Chapters
    
    internal static func extractChapters(from html: String, forWorkID workID: Int) -> [Int: String] {
        (try? withDocument(html: html) { doc in
            var chapters: [Int: String] = [:]
            
            if let chapterSelect = try doc.select("select#selected_id, select[name='selected_id']").first() {
                let options = try chapterSelect.select("option").array()
                for (index, option) in options.enumerated() {
                    if let chapterID = Int(try option.attr("value")) {
                        chapters[chapterID] = cleanChapterTitle(try option.text(), fallbackIndex: index + 1)
                    }
                }
            }
            
            if chapters.isEmpty,
               let regex = try? NSRegularExpression(pattern: "/works/\(workID)/chapters/(\\d+)") {
                let nsRange = NSRange(html.startIndex..., in: html)
                let foundIDs = Set(regex.matches(in: html, range: nsRange).compactMap { match -> Int? in
                    guard let range = Range(match.range(at: 1), in: html) else { return nil }
                    return Int(html[range])
                })
                for (index, chapterID) in foundIDs.sorted().enumerated() {
                    chapters[chapterID] = "Chapter \(index + 1)"
                }
            }
            
            return chapters
        }) ?? [:]
    }
    
    // MARK: - CSRF Token Parser
    
    public static func parseCSRFToken(from html: String) throws -> String {
        if let token = extractCSRFTokenFast(from: html) {
            return token
        }
        return try withDocument(html: html) { doc in
            guard let token = doc.firstAttr("meta[name=csrf-token]", "content") else {
                throw AO3ClientError.invalidData
            }
            return token
        }
    }
    
    internal static func extractCSRFTokenFast(from html: String) -> String? {
        let headEnd = html.range(of: "</head>", options: .caseInsensitive)?.lowerBound ?? html.endIndex
        let headSlice = html[..<headEnd]
        
        guard let metaRange = headSlice.range(of: #"name="csrf-token""#),
              let lineStart = headSlice[..<metaRange.lowerBound].range(of: "<meta", options: .backwards)?.lowerBound,
              let tagEnd = headSlice[metaRange.upperBound...].range(of: ">")?.upperBound else {
            return nil
        }
        
        let metaTag = headSlice[lineStart..<tagEnd]
        guard let contentStart = metaTag.range(of: #"content=""#)?.upperBound,
              let contentEnd = metaTag[contentStart...].firstIndex(of: "\"") else {
            return nil
        }
        
        let token = String(metaTag[contentStart..<contentEnd])
        return token.isEmpty ? nil : token
    }
    
    //MARK: - Logged In User Fast Parser
    
    /// Scans the top of an AO3 HTML document for the logged-in username inside `#greeting` without building a DOM tree.
    internal static func extractCurrentUsernameFast(from html: String) -> String? {
        guard let greetingRange = html.range(of: #"id="greeting""#) else {
            return nil
        }
        
        let searchEnd = html.index(greetingRange.upperBound, offsetBy: 1500, limitedBy: html.endIndex) ?? html.endIndex
        let greetingSlice = html[greetingRange.upperBound..<searchEnd]
        
        guard let hrefStart = greetingSlice.range(of: #"href="/users/"#)?.upperBound,
              let hrefEnd = greetingSlice[hrefStart...].firstIndex(where: { $0 == "\"" || $0 == "/" || $0 == "?" }) else {
            return nil
        }
        
        let rawUsername = String(greetingSlice[hrefStart..<hrefEnd])
        let decoded = rawUsername.removingPercentEncoding ?? rawUsername
        return decoded.isEmpty ? nil : decoded
    }

}



internal extension Element {
    /// Returns the trimmed text of the first element matching `selector`, or `nil` if not found/empty.
    func firstText(_ selector: String) -> String? {
        guard let text = try? select(selector).first()?.text().trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }
        return text
    }
    
    /// Returns the text of all elements matching `selector`.
    func texts(_ selector: String) -> [String] {
        (try? select(selector).array().compactMap { try? $0.text() }) ?? []
    }
    
    /// Parses an integer (stripping commas) from the first element matching `selector`.
    func firstInt(_ selector: String) -> Int? {
        AO3Parser.parseInt(firstText(selector))
    }
    
    /// Returns the attribute value of the first element matching `selector`.
    func firstAttr(_ selector: String, _ attribute: String) -> String? {
        guard let val = try? select(selector).first()?.attr(attribute), !val.isEmpty else { return nil }
        return val
    }
}
