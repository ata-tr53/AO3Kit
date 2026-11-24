//
//  AO3ChallengeParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    static func parseUserSignups(html: String) throws -> [AO3ChallengeSignup] {
        try parseElements(html: html, selector: "dl.signup.index.group > dt, ol.signup.index > li, ul.index > li") { element in
            guard let signupLink = try element.select("a[href*='/signups/']").first(),
                  let href = try? signupLink.attr("href") else {
                return nil
            }
            let parts = href.split(separator: "/").map(String.init)
            guard let idx = parts.firstIndex(of: "signups"), idx + 1 < parts.count,
                  let id = Int(parts[idx + 1]) else {
                return nil
            }

            let collectionLink = try element.select("a[href^='/collections/']").first()
            let collectionID = (try? collectionLink?.attr("href"))?.split(separator: "/").dropFirst().first.map(String.init)
            let collectionTitle = (try? collectionLink?.text().trimmingCharacters(in: .whitespacesAndNewlines))
                ?? (try? signupLink.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
            let fullURL = href.hasPrefix("http") ? URL(string: href) : URL(string: "https://archiveofourown.org\(href)")

            return AO3ChallengeSignup(
                id: id,
                collectionID: collectionID,
                collectionTitle: collectionTitle,
                url: fullURL
            )
        }
    }

    static func parseUserAssignments(html: String) throws -> [AO3ChallengeAssignment] {
        try parseElements(html: html, selector: "dl.assignment.index.group > dt, ol.assignment.index > li, li.assignment") { element in
            guard let link = try element.select("a[href*='/assignments/']").first(),
                  let href = try? link.attr("href") else {
                return nil
            }
            let parts = href.split(separator: "/").map(String.init)
            guard let idx = parts.firstIndex(of: "assignments"), idx + 1 < parts.count,
                  let id = Int(parts[idx + 1]) else {
                return nil
            }

            let collectionLink = try element.select("a[href^='/collections/']").first()
            let collectionID = (try? collectionLink?.attr("href"))?.split(separator: "/").dropFirst().first.map(String.init)
            let collectionTitle = (try? collectionLink?.text().trimmingCharacters(in: .whitespacesAndNewlines))
                ?? (try? link.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
            let recipient = element.firstText("a[href^='/users/']")
            let dueDate = element.firstText("p.datetime, span.datetime")
            let status = element.firstText("p.status, span.status")
            let fullURL = href.hasPrefix("http") ? URL(string: href) : URL(string: "https://archiveofourown.org\(href)")

            return AO3ChallengeAssignment(
                id: id,
                collectionID: collectionID,
                collectionTitle: collectionTitle,
                recipient: recipient,
                dueDate: dueDate,
                status: status,
                url: fullURL
            )
        }
    }

    static func parseUserClaims(html: String) throws -> [AO3ChallengeClaim] {
        try parseElements(html: html, selector: "ol.claim.index > li, ul.claim.index > li, li.claim") { element in
            guard let link = try element.select("a[href*='/claims/'], a[href*='/prompts/']").first(),
                  let href = try? link.attr("href") else {
                return nil
            }
            let parts = href.split(separator: "/").map(String.init)
            let id = parts.reversed().compactMap(Int.init).first ?? 0
            guard id > 0 else { return nil }

            let collectionLink = try element.select("a[href^='/collections/']").first()
            let collectionID = (try? collectionLink?.attr("href"))?.split(separator: "/").dropFirst().first.map(String.init)
            let collectionTitle = (try? collectionLink?.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
            let promptTitle = element.firstText("h4.heading")
            let requester = element.firstText("a[href^='/users/']")
            let isFulfilled = (try? element.text().localizedCaseInsensitiveContains("fulfilled")) == true
            let fullURL = href.hasPrefix("http") ? URL(string: href) : URL(string: "https://archiveofourown.org\(href)")

            return AO3ChallengeClaim(
                id: id,
                collectionID: collectionID,
                collectionTitle: collectionTitle,
                promptTitle: promptTitle,
                requester: requester,
                isFulfilled: isFulfilled,
                url: fullURL
            )
        }
    }

    static func parseTagSets(html: String) throws -> [AO3TagSetPreview] {
        try parseElements(html: html, selector: "ol.tagset.index > li, li.tagset.blurb, ul.index > li.blurb") { element in
            guard let titleLink = try element.select("h4.heading a[href^='/tag_sets/']").first(),
                  let href = try? titleLink.attr("href"),
                  let idStr = href.split(separator: "/").last,
                  let id = Int(idStr),
                  let title = try? titleLink.text().trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty else {
                return nil
            }

            let owners = element.texts("h4.heading a[href^='/users/'], h5.heading a[href^='/users/']")
            let description = extractText(from: try element.select("blockquote.userstuff").first())
            let isNominationOpen = (try? element.text().localizedCaseInsensitiveContains("nominations open")) == true

            return AO3TagSetPreview(
                id: id,
                title: title,
                owners: owners,
                description: description,
                isNominationOpen: isNominationOpen
            )
        }
    }

    static func parseUserNominations(html: String) throws -> [AO3TagSetNomination] {
        try parseElements(html: html, selector: "ol.nomination.index > li, ul.index > li") { element in
            guard let link = try element.select("a[href*='/nominations/']").first(),
                  let href = try? link.attr("href") else {
                return nil
            }
            let parts = href.split(separator: "/").map(String.init)
            guard let nomIdx = parts.firstIndex(of: "nominations"), nomIdx + 1 < parts.count,
                  let id = Int(parts[nomIdx + 1]) else {
                return nil
            }

            let tagSetID: Int?
            if let setIdx = parts.firstIndex(of: "tag_sets"), setIdx + 1 < parts.count {
                tagSetID = Int(parts[setIdx + 1])
            } else {
                tagSetID = nil
            }

            let title = element.firstText("a[href^='/tag_sets/']")
                ?? (try? link.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
            let fullURL = href.hasPrefix("http") ? URL(string: href) : URL(string: "https://archiveofourown.org\(href)")

            return AO3TagSetNomination(
                id: id,
                tagSetID: tagSetID,
                tagSetTitle: title,
                url: fullURL
            )
        }
    }
}
