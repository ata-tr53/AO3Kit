//
//  AO3Parser.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import SwiftSoup
import Foundation

public struct AO3Parser {
    
    // MARK: - Pagination Parser
    
    internal static func parsePagination(html: String) throws -> (currentPage: Int, totalPages: Int) {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            defer { doc.empty() }
            
            guard let paginationList = try doc.select("ol.pagination").first() else {
                return (1, 1)
            }
            
            let currentString = try paginationList.select(".current").first()?.text() ?? "1"
            let currentPage = Int(currentString) ?? 1
            
            let pageLinks = try paginationList.select("li a[href*='page=']").array()
            var maxPage = currentPage
            
            for link in pageLinks {
                if let pageNum = Int(try link.text()), pageNum > maxPage {
                    maxPage = pageNum
                }
            }
            
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
        return autoreleasepool {
            var chapters: [Int: String] = [:]
            
            do {
                let doc = try SwiftSoup.parse(html)
                
                defer {
                    doc.empty()
                }
                
                if let chapterSelect = try doc.select("select#selected_id, select[name='selected_id']").first() {
                    let options = try chapterSelect.select("option").array()
                    
                    for (index, option) in options.enumerated() {
                        let value = try option.attr("value")
                        let rawTitle = try option.text()
                        
                        if let chapterID = Int(value) {
                            var cleanTitle = rawTitle
                            
                            if let range = cleanTitle.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
                                cleanTitle.removeSubrange(range)
                            }
                            
                            if cleanTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                                cleanTitle = "Chapter \(index + 1)"
                            }
                            
                            chapters[chapterID] = cleanTitle
                        }
                    }
                    print("Dropdown chapters count: \(options.count)")
                }
                
                if chapters.isEmpty {
                    let pattern = "/works/\(workID)/chapters/(\\d+)"
                    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                        let nsRange = NSRange(html.startIndex..., in: html)
                        let matches = regex.matches(in: html, range: nsRange)
                        var foundChapterIDs = Set<Int>()
                        for match in matches {
                            if let range = Range(match.range(at: 1), in: html),
                               let chapterID = Int(html[range]) {
                                foundChapterIDs.insert(chapterID)
                            }
                        }
                        
                        let sortedIDs = foundChapterIDs.sorted()
                        for (index, chapterID) in sortedIDs.enumerated() {
                            chapters[chapterID] = "Chapter \(index + 1)"
                        }
                    }
                }
                
                print("Extracted Chapters for work \(workID): \(chapters)")
                return chapters
            } catch {
                print("Error extracting chapters: \(error)")
                return [:]
            }
        }
    }
    
    // MARK: - CSRF Token Parser
    
    public static func parseCSRFToken(from html: String) throws -> String {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            guard let tokenTag = try doc.select("meta[name=csrf-token]").first() else {
                throw AO3ClientError.invalidData
            }
            
            let token = try tokenTag.attr("content")
            guard !token.isEmpty else {
                throw AO3ClientError.invalidData
            }
            
            return token
        }
    }

}

