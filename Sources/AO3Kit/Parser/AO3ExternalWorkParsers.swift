//
//  AO3ExternalWorkParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    static func parseExternalWork(html: String, id: Int) throws -> AO3ExternalWork {
        try withDocument(html: html) { doc in
            let titleLink = try doc.select("div.external.work h4.heading a, h2.heading a, div.work h4.heading a").first()
            let title = (try? titleLink?.text().trimmingCharacters(in: .whitespacesAndNewlines))
                ?? doc.firstText("h2.heading") ?? "Unknown External Work"
            let externalURL = (try? titleLink?.attr("href")).flatMap(URL.init(string:))

            let author = doc.firstText("h4.heading a[rel=author], h3.byline.heading")
                ?? doc.firstText("h4.heading") ?? "Unknown"
            let summary = extractText(from: try doc.select("blockquote.userstuff.summary, blockquote.summary").first())

            let fandoms = doc.texts("h5.fandoms a.tag, dd.fandom.tags a.tag")
            let relationships = doc.texts("li.relationships a.tag, dd.relationship.tags a.tag")
            let characters = doc.texts("li.characters a.tag, dd.character.tags a.tag")
            let additionalTags = doc.texts("li.freeforms a.tag, dd.freeform.tags a.tag")

            let ratingText = doc.firstAttr("span.rating", "title") ?? doc.firstText("dd.rating.tags a.tag") ?? ""
            let rating = mapContentRating(ratingText)

            let categoryTexts = doc.texts("dd.category.tags a.tag")
            let categories: [AO3RelationshipCategory]
            if !categoryTexts.isEmpty {
                categories = categoryTexts.compactMap(mapRelationshipCategory)
            } else {
                let rawCat = doc.firstAttr("span.category", "title") ?? ""
                categories = rawCat.components(separatedBy: ", ").compactMap {
                    mapRelationshipCategory($0.trimmingCharacters(in: .whitespaces))
                }
            }

            let bookmarkCount = doc.firstInt("dd.bookmarks a, dd.bookmarks") ?? 0

            return AO3ExternalWork(
                id: id,
                title: title,
                author: author,
                externalURL: externalURL,
                summary: summary,
                fandoms: fandoms,
                relationships: relationships,
                characters: characters,
                additionalTags: additionalTags,
                rating: rating,
                categories: categories,
                bookmarkCount: bookmarkCount
            )
        }
    }
}
