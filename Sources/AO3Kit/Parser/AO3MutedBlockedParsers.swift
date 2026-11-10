//
//  AO3MutedBlockedParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 6.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    static func parseMutedOrBlockedUsers(html: String) throws -> [AO3MutedBlockedLink] {
        try parseElements(html: html, selector: "ul.pseud.index li.user.pseud.blurb") { element in
            let profilePicture = parseImage(from: try element.select("div.icon img").first())
            guard let authorLink = parseAuthorLink(
                from: try element.select("div.header h4.heading a").first(),
                profilePicture: profilePicture
            ) else { return nil }
            
            let (unblockActionID, unmuteActionID) = parseModerationActionIDs(in: element, selector: "ul.actions a")
            guard unblockActionID != nil || unmuteActionID != nil else { return nil }
            
            return AO3MutedBlockedLink(
                authorLink: authorLink,
                unmuteActionID: unmuteActionID,
                unblockActionID: unblockActionID
            )
        }
    }
    
}
