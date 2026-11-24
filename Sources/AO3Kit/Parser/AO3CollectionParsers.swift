//
//  AO3CollectionParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - Collection Profile Parser
    
    static func parseCollectionProfile(html: String, collectionID: String) throws -> AO3Collection {
        try withDocument(html: html) { doc in
            let displayName = doc.firstText("h2.heading a[href^='/collections/']") ?? collectionID
            let icon = parseImage(from: try doc.select("div.primary.header.module img.icon").first())
            let maintainers = parseAuthorLinks(in: doc, selector: "dl.meta dd.maintainers a")
            
            var parentCollection: AO3CollectionLink? = nil
            if let href = doc.firstAttr("div#dashboard ul.navigation.actions a:contains(Parent Collection)", "href"),
               let parentID = href.components(separatedBy: "/").last, !parentID.isEmpty {
                let cleanID = parentID.removingPercentEncoding ?? parentID
                parentCollection = AO3CollectionLink(id: cleanID, displayName: cleanID)
            }
            
            let options = parseCollectionOptions(from: doc.firstText("p.type") ?? "")
            
            let challengeText = doc.firstText("dl.meta dt:contains(Challenge) + dd") ?? ""
            let challengeType: AO3ChallengeType? = if challengeText.contains("Gift Exchange") {
                .giftExchange
            } else if challengeText.contains("Prompt Meme") {
                .promptMeme
            } else {
                nil
            }
            
            let summaryHTML = try doc.select("div.primary.header.module blockquote.userstuff").first()?.html()
            let rulesHTML = try doc.select("div.collection.rules.module blockquote.userstuff").first()?.html()
            let faqHTML = try doc.select("div.collection.faq.module blockquote.userstuff").first()?.html()
            
            let parenRegex = try? NSRegularExpression(pattern: #"\(([\d,]+)\)"#)
            func parseStat(for path: String) -> Int {
                guard let text = doc.firstText("div#dashboard ul.navigation.actions a[href$='/\(path)']"),
                      let match = parenRegex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                      let range = Range(match.range(at: 1), in: text) else { return 0 }
                return parseInt(String(text[range])) ?? 0
            }
            
            let dateText = doc.firstText("dl.meta dt:contains(Active since) + dd") ?? ""
            let activeDate = DateFormatter.ao3DateFormatter.date(from: dateText) ?? Date()
            
            return AO3Collection(
                id: collectionID,
                displayName: displayName,
                icon: icon,
                maintainers: maintainers,
                parentCollection: parentCollection,
                summaryHTML: summaryHTML,
                faqHTML: faqHTML,
                rulesHTML: rulesHTML,
                options: options,
                challengeType: challengeType,
                fandomCount: parseStat(for: "fandoms"),
                workCount: parseStat(for: "works"),
                bookmarkCount: parseStat(for: "bookmarks"),
                subCollectionCount: parseStat(for: "collections"),
                date: activeDate
            )
        }
    }
    
    // MARK: - Collection Previews Parser
    
    static func parseCollectionPreviews(html: String) throws -> [AO3CollectionPreview] {
        try parseElements(html: html, selector: "li.collection.picture.blurb.group") { element in
            guard let href = element.firstAttr("h4.heading a[href^='/collections/']", "href"),
                  let id = href.components(separatedBy: "/").last,
                  !id.isEmpty else { return nil }
            
            let displayName = element.firstText("h4.heading a[href^='/collections/']") ?? id
            let icon = parseImage(from: try element.select("div.icon img.icon").first())
            let maintainers = parseAuthorLinks(in: element, selector: "h4.heading a.owner")
            let date = DateFormatter.ao3BlurbDateFormatter.date(from: element.firstText("p.datetime") ?? "") ?? Date()
            let summaryHTML = try element.select("blockquote.userstuff.summary").html()
            let options = parseCollectionOptions(from: element.firstText("p.type") ?? "")
            
            return AO3CollectionPreview(
                id: id,
                displayName: displayName,
                icon: icon,
                maintainers: maintainers,
                summaryHTML: summaryHTML.isEmpty ? nil : summaryHTML,
                options: options,
                workCount: element.firstInt("dl.stats dd.works a") ?? 0,
                bookmarkCount: element.firstInt("dl.stats dd.bookmarks a") ?? 0,
                date: date
            )
        }
    }
    
    private static func parseCollectionOptions(from statusText: String) -> AO3CollectionOptions {
        var options = AO3CollectionOptions(rawValue: 0)
        if !statusText.contains("Closed") { options.insert(.open) }
        if statusText.contains("Moderated") { options.insert(.moderated) }
        if statusText.contains("Unrevealed") { options.insert(.unrevealed) }
        if statusText.contains("Anonymous") { options.insert(.anonymous) }
        return options
    }

    // MARK: - Collection Prompts / Requests Parser

    static func parseCollectionPrompts(html: String) throws -> [AO3CollectionPrompt] {
        try parseElements(html: html, selector: "ul.prompt.index.group > li.prompt.blurb.group") { element in
            let rawID = element.id().replacingOccurrences(of: "prompt_", with: "")
            let inputID = element.firstAttr("input[name='prompt_id']", "value")
            guard let promptID = Int(rawID) ?? inputID.flatMap(Int.init) else { return nil }

            let headingText = element.firstText("h4.heading") ?? ""
            let requester = parseAuthorLink(from: try element.select("h4.heading a[href^='/users/']").first())
            let isAnonymous = requester == nil && headingText.localizedCaseInsensitiveContains("Anonymous")

            let title = element.firstText("h4.heading a:not([href^='/users/'])")
            let fandoms = element.texts("h5.fandoms a.tag")
            let tags = element.texts("ul.tags li:not(.optional) a.tag")
            let optionalTags = element.texts("ul.tags li.optional a.tag")
            let descriptionHTML = try element.select("blockquote.userstuff").first()?.html()

            let claimsText = element.firstText("p.claims, dd.claims") ?? ""
            let claimCount = claimsText
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap(Int.init)
                .first ?? 0

            return AO3CollectionPrompt(
                id: promptID,
                title: title,
                requester: requester,
                isAnonymous: isAnonymous,
                fandoms: fandoms,
                tags: tags,
                optionalTags: optionalTags,
                descriptionHTML: descriptionHTML?.isEmpty == true ? nil : descriptionHTML,
                claimCount: claimCount
            )
        }
    }

    static func parseCollectionLeaveParticipantID(from html: String) throws -> Int? {
        try withDocument(html: html) { doc in
            let selectors = [
                "a[href*='/participants/'][data-method='delete']",
                "form[action*='/participants/']:has(input[name='_method'][value='delete'])"
            ]
            for selector in selectors {
                if let el = try doc.select(selector).first() {
                    let path = (try? el.attr("href")).flatMap { $0.isEmpty ? nil : $0 }
                        ?? (try? el.attr("action")) ?? ""
                    if let last = path.split(separator: "/").last, let id = Int(last) {
                        return id
                    }
                }
            }
            return nil
        }
    }

    // MARK: - User Collection Items Parser (/users/:username/collection_items)

    static func parseUserCollectionItems(html: String) throws -> [AO3CollectionItem] {
        try parseElements(html: html, selector: "ul.collection.item.index > li, ol.index > li.collection.item") { element in
            guard let statusSelect = try element.select("select[name*='collection_items['][name*='user_approval_status']").first(),
                  let selectName = try? statusSelect.attr("name") else {
                return nil
            }

            let idString = selectName
                .replacingOccurrences(of: "collection_items[", with: "")
                .components(separatedBy: "]")
                .first ?? ""
            guard let itemID = Int(idString) else { return nil }

            let collectionLink = try element.select("a[href^='/collections/']").first()
            let collectionTitle = (try? collectionLink?.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
            let collectionID = (try? collectionLink?.attr("href"))?.split(separator: "/").last.map(String.init)

            let workLink = try element.select("a[href^='/works/']").first()
            let workTitle = (try? workLink?.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
            let workID = (try? workLink?.attr("href"))?.split(separator: "/").last.flatMap { Int($0) }

            let selectedValue = (try? statusSelect.select("option[selected]").first()?.attr("value")) ?? ""
            let status = AO3CollectionItemStatus(rawValue: selectedValue.lowercased()) ?? .unreviewed

            return AO3CollectionItem(
                id: itemID,
                collectionID: collectionID,
                collectionTitle: collectionTitle,
                workID: workID,
                workTitle: workTitle,
                status: status
            )
        }
    }
}
