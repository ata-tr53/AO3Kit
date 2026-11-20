//
//  AO3DashboardParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    // MARK: - Collection Tags Parser (/collections/:id/tags)

    static func parseCollectionTags(html: String) throws -> [AO3FandomEntry] {
        try parseElements(html: html, selector: "ol.tag.index li, ul.tags.cloud li, ol.alphabet.tag.index li ul.tags li") { element in
            guard let link = try element.select("a.tag").first(),
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

    // MARK: - Related Works Parser (/users/:username/related_works)

    static func parseRelatedWorks(html: String) throws -> [AO3RelatedWork] {
        try withDocument(html: html) { doc in
            let dtElements = try doc.select("dl.index dt").array()
            var results: [AO3RelatedWork] = []

            for (idx, dt) in dtElements.enumerated() {
                let workLink = try dt.select("a[href^='/works/']").first()
                let workTitle = (try? workLink?.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                guard !workTitle.isEmpty else { continue }

                let workHref = (try? workLink?.attr("href")) ?? ""
                let workURL = workHref.isEmpty ? nil : URL(string: workHref.hasPrefix("http") ? workHref : "https://archiveofourown.org\(workHref)")
                let authorName = dt.firstText("a[rel=author]")

                var relatedID = idx + 1
                var parentTitle: String? = nil
                var parentURL: URL? = nil
                var isTranslation = false
                var isApproved = true

                if let dd = try? dt.nextElementSibling(), dd.tagName().lowercased() == "dd" {
                    let ddText = (try? dd.text()) ?? ""
                    isTranslation = ddText.localizedCaseInsensitiveContains("translation")
                    isApproved = !ddText.localizedCaseInsensitiveContains("approve")

                    if let parentLink = try dd.select("a[href^='/works/'], a[href^='/external_works/']").first() {
                        parentTitle = try? parentLink.text().trimmingCharacters(in: .whitespacesAndNewlines)
                        if let pHref = try? parentLink.attr("href"), !pHref.isEmpty {
                            parentURL = URL(string: pHref.hasPrefix("http") ? pHref : "https://archiveofourown.org\(pHref)")
                        }
                    }

                    if let relLink = try dd.select("a[href*='/related_works/'], form[action*='/related_works/']").first() {
                        let rawPath = (try? relLink.attr("href")).flatMap { $0.isEmpty ? nil : $0 }
                            ?? (try? relLink.attr("action")) ?? ""
                        let digits = rawPath.split(separator: "/").compactMap { Int($0) }.last
                        if let digits { relatedID = digits }
                    }
                }

                results.append(
                    AO3RelatedWork(
                        id: relatedID,
                        workTitle: workTitle,
                        workURL: workURL,
                        authorName: authorName,
                        parentTitle: parentTitle,
                        parentURL: parentURL,
                        isTranslation: isTranslation,
                        isApproved: isApproved
                    )
                )
            }

            return results
        }
    }

    // MARK: - Co-Creator Requests Parser (/users/:username/creatorships)

    static func parseCoCreatorRequests(html: String) throws -> [AO3CoCreatorRequest] {
        try parseElements(html: html, selector: "ol.creatorship.index li, ul.creatorship.index li, table#creatorships tbody tr") { element in
            guard let idVal = element.firstAttr("input[type=checkbox][name='selected[]']", "value")
                ?? element.firstAttr("input[name*='creatorship']", "value"),
                  let id = Int(idVal) else {
                return nil
            }

            let creationLink = try element.select("a[href^='/works/'], a[href^='/series/'], a[href^='/chapters/']").first()
            let title = (try? creationLink?.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? "Untitled"
            let href = (try? creationLink?.attr("href")) ?? ""
            let url = href.isEmpty ? nil : URL(string: href.hasPrefix("http") ? href : "https://archiveofourown.org\(href)")

            let creationType: String
            if href.contains("/series/") {
                creationType = "Series"
            } else if href.contains("/chapters/") {
                creationType = "Chapter"
            } else {
                creationType = "Work"
            }

            let pseudName = element.firstText("a[href*='/pseuds/']")

            return AO3CoCreatorRequest(
                id: id,
                creationTitle: title,
                creationURL: url,
                creationType: creationType,
                pseudName: pseudName
            )
        }
    }
}
