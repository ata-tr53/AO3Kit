//
//  AO3TagParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    // MARK: - Tag Details Parser (/tags/:name)

    static func parseTagDetails(html: String, tagName: String) throws -> AO3TagDetails {
        try withDocument(html: html) { doc in
            let resolvedName = doc.firstText("div.tag.home.profile h2.heading") ?? tagName

            let summaryParagraphs = doc.texts("div.tag.home.profile > p")
            let fullIntro = summaryParagraphs.joined(separator: " ")

            var category: String? = nil
            if let range = fullIntro.range(of: #"belongs to the ([^.]+?) category"#, options: .regularExpression) {
                let match = String(fullIntro[range])
                    .replacingOccurrences(of: "belongs to the ", with: "")
                    .replacingOccurrences(of: " category", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !match.isEmpty { category = match }
            }

            let isCanonical = fullIntro.contains("common tag") || fullIntro.contains("canonical")
            let canonicalMerger = doc.firstText("div.merger.module a.tag")

            let parentTags = doc.texts("div.parent.listbox ul.tags a.tag")
            let synonyms = doc.texts("div.synonym.listbox ul.tags a.tag")
            let metaTags = doc.texts("div.meta.listbox ul.tags a.tag")
            let subTags = doc.texts("div.sub.listbox ul.tags a.tag")

            var childCategories: [String: [String]] = [:]
            for childBox in try doc.select("div.child.listbox").array() {
                if let heading = childBox.firstText("h3.heading, h4.heading") {
                    let tags = childBox.texts("ul.tags a.tag")
                    if !tags.isEmpty {
                        childCategories[heading] = tags
                    }
                }
            }

            return AO3TagDetails(
                name: resolvedName,
                category: category,
                isCanonical: isCanonical,
                canonicalMerger: canonicalMerger,
                parentTags: parentTags,
                synonyms: synonyms,
                metaTags: metaTags,
                subTags: subTags,
                childCategories: childCategories
            )
        }
    }

    static func parseTagFeedURL(from html: String) throws -> URL? {
        try withDocument(html: html) { doc in
            guard let href = try doc.select("link[rel=alternate][type='application/atom+xml']").first()?.attr("href"),
                  !href.isEmpty else {
                return nil
            }
            return href.hasPrefix("http") ? URL(string: href) : URL(string: "https://archiveofourown.org\(href)")
        }
    }

    // MARK: - Media Categories Parser (/media)

    static func parseMediaCategories(html: String) throws -> [AO3MediaCategory] {
        try parseElements(html: html, selector: "ol.media.index > li.medium.listbox") { element in
            guard let headingLink = try element.select("h3.heading a").first(),
                  let name = try? headingLink.text().trimmingCharacters(in: .whitespacesAndNewlines),
                  let href = try? headingLink.attr("href"),
                  !name.isEmpty else {
                return nil
            }

            // Extract media ID from /media/:id/fandoms
            let parts = href.split(separator: "/").map(String.init)
            let rawMediaID: String
            if let mediaIdx = parts.firstIndex(of: "media"), mediaIdx + 1 < parts.count {
                rawMediaID = parts[mediaIdx + 1].removingPercentEncoding ?? parts[mediaIdx + 1]
            } else {
                rawMediaID = name
            }

            let fandomItems = (try? element.select("ol.index li").array()) ?? []
            let featured = fandomItems.compactMap(parseFandomListItem)

            return AO3MediaCategory(
                id: rawMediaID,
                name: name,
                featuredFandoms: featured
            )
        }
    }

    // MARK: - Fandoms Directory Parser (/media/:id/fandoms & /fandoms/unassigned)

    static func parseFandomsDirectory(html: String) throws -> [AO3FandomEntry] {
        try parseElements(html: html, selector: "ol.alphabet.fandom.index li.letter ul.tags li, ol.fandom.index li") { element in
            parseFandomListItem(element)
        }
    }

    private static func parseFandomListItem(_ element: Element) -> AO3FandomEntry? {
        guard let link = try? element.select("a.tag").first(),
              let name = try? link.text().trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return nil
        }

        let ownText = element.ownText()
        var count = 0
        if let regex = try? NSRegularExpression(pattern: #"\(([\d,]+)\)"#),
           let match = regex.firstMatch(in: ownText, range: NSRange(ownText.startIndex..., in: ownText)),
           let range = Range(match.range(at: 1), in: ownText) {
            count = parseInt(String(ownText[range])) ?? 0
        }

        return AO3FandomEntry(name: name, workCount: count)
    }
}
