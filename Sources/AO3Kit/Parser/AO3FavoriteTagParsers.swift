//
//  AO3FavoriteTagParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation
import SwiftSoup

internal struct AO3FavoriteTagActionContext: Sendable {
    let csrfToken: String
    let tagID: Int?
    let favoriteTagRecordID: Int?
}

public extension AO3Parser {
    /// Parses the logged-in user's favorite tags from the AO3 home page (`/`).
    static func parseFavoriteTags(html: String) throws -> [AO3FavoriteTag] {
        try withDocument(html: html) { doc in
            let links = try doc.select("div.favorite.module ul.index a[href^='/tags/'], div.favorite.module a.tag[href^='/tags/']").array()
            var seen: Set<String> = []
            var tags: [AO3FavoriteTag] = []

            for link in links {
                let text = (try? link.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                guard !text.isEmpty, seen.insert(text).inserted else { continue }
                tags.append(AO3FavoriteTag(name: text))
            }

            return tags
        }
    }

    /// Parses the Favorite / Unfavorite Tag form context from a tag's works page (`/tags/:name/works`).
    internal static func parseFavoriteTagActionContext(from html: String) throws -> AO3FavoriteTagActionContext {
        let csrfToken = try parseCSRFToken(from: html)

        return try withDocument(html: html) { doc in
            var tagID: Int? = nil
            if let tagInputVal = doc.firstAttr("input[name='favorite_tag[tag_id]']", "value") {
                tagID = Int(tagInputVal)
            }

            var recordID: Int? = nil
            if let unfavoriteForm = try doc.select("form[action*='/favorite_tags/']").first(),
               let action = try? unfavoriteForm.attr("action"),
               let lastPart = action.split(separator: "/").last,
               let parsedID = Int(lastPart) {
                recordID = parsedID
            }

            return AO3FavoriteTagActionContext(
                csrfToken: csrfToken,
                tagID: tagID,
                favoriteTagRecordID: recordID
            )
        }
    }
}
