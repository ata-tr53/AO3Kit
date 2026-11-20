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
}
