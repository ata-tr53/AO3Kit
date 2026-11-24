//
//  AO3SkinParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    static func parseSkins(html: String) throws -> [AO3Skin] {
        try parseElements(html: html, selector: "ol.skin.index li.skin.blurb") { element in
            guard let titleLink = try element.select("h4.heading a[href^='/skins/']").first(),
                  let href = try? titleLink.attr("href"),
                  let idStr = href.split(separator: "/").last,
                  let id = Int(idStr),
                  let title = try? titleLink.text().trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty else {
                return nil
            }

            let author = element.firstText("h4.heading a[rel=author], h4.heading span.byline")
            let description = extractText(from: try element.select("blockquote.userstuff").first())
            let icon = parseImage(from: try element.select("div.icon img").first())
            let isWorkSkin = element.hasClass("work") || (try? element.select("p.type").text().localizedCaseInsensitiveContains("work skin")) == true
            let isActive = (try? !element.select("form[action='/skins/unset']").isEmpty()) == true

            return AO3Skin(
                id: id,
                title: title,
                author: author,
                description: description,
                icon: icon,
                type: isWorkSkin ? .work : .site,
                isActive: isActive
            )
        }
    }

    static func parseSkinDetails(html: String, id: Int) throws -> AO3SkinDetails {
        try withDocument(html: html) { doc in
            let title = doc.firstText("div.skin.primary.header h2.heading, h2.heading") ?? "Skin \(id)"
            let author = doc.firstText("h3.byline a[rel=author], dl.meta dd.author a, h3.byline")
            let description = extractText(from: try doc.select("div.skin blockquote.userstuff, div.description blockquote.userstuff").first())
            let css = (try? doc.select("div.css.module pre, div.css blockquote pre, pre.css").first()?.text()) ?? ""
            let icon = parseImage(from: try doc.select("div.primary.header img.icon, div.icon img").first())

            let typeText = (doc.firstText("p.type, dl.meta dd.type") ?? "").lowercased()
            let type: AO3SkinType = typeText.contains("work") ? .work : .site

            let mediaText = doc.firstText("dl.meta dt:contains(Media) + dd") ?? ""
            let media = mediaText
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let role = doc.firstText("dl.meta dt:contains(Role) + dd")
            let parentSkins = doc.texts("div.parent.module a[href^='/skins/'], ul.parents a[href^='/skins/']")
            let isPublic = typeText.contains("public") || (try? !doc.select("span.public").isEmpty()) == true
            let isActive = (try? !doc.select("form[action='/skins/unset']").isEmpty()) == true

            return AO3SkinDetails(
                id: id,
                title: title,
                author: author,
                description: description,
                css: css,
                type: type,
                media: media,
                role: role,
                parentSkins: parentSkins,
                isPublic: isPublic,
                isActive: isActive,
                icon: icon
            )
        }
    }

    internal static func parseSkinIDFromResponse(html: String) throws -> Int? {
        try withDocument(html: html) { doc in
            let selectors = [
                "link[rel='canonical'][href*='/skins/']",
                "a[href^='/skins/'][href$='/edit']",
                "form[action^='/skins/']"
            ]
            for selector in selectors {
                if let el = try doc.select(selector).first() {
                    let raw = (try? el.attr("href")).flatMap { $0.isEmpty ? nil : $0 }
                        ?? (try? el.attr("action")) ?? ""
                    let parts = raw.split(separator: "/")
                    if let idx = parts.firstIndex(of: "skins"), idx + 1 < parts.count,
                       let id = Int(parts[idx + 1]) {
                        return id
                    }
                }
            }
            return nil
        }
    }
}
