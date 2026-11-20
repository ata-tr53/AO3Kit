//
//  AO3KudosParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    static func parseWorkKudos(html: String, workID: Int) throws -> AO3WorkKudos {
        try withDocument(html: html) { doc in
            guard let kudosParagraph = try doc.select("div#kudos p.kudos, p.kudos").first() else {
                return AO3WorkKudos(workID: workID, users: [], guestCount: 0)
            }

            let userLinks = (try? kudosParagraph.select("a[href^='/users/']").array()) ?? []
            let users = userLinks.compactMap { parseAuthorLink(from: $0) }

            let fullText = (try? kudosParagraph.text()) ?? ""
            var guestCount = 0
            if let regex = try? NSRegularExpression(pattern: #"(\d[\d,]*)\s+guests?"#, options: .caseInsensitive),
               let match = regex.firstMatch(in: fullText, range: NSRange(fullText.startIndex..., in: fullText)),
               let range = Range(match.range(at: 1), in: fullText) {
                guestCount = parseInt(String(fullText[range])) ?? 0
            } else if fullText.localizedCaseInsensitiveContains("a guest") {
                guestCount = 1
            }

            return AO3WorkKudos(
                workID: workID,
                users: users,
                guestCount: guestCount
            )
        }
    }
}
