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
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            defer { doc.empty() }
            
            let userElements = try doc.select("ul.pseud.index li.user.pseud.blurb").array()
            
            return userElements.compactMap { element in
                do {
                    let titleLink = try element.select("div.header h4.heading a").first()
                    let href = try titleLink?.attr("href") ?? ""
                    let displayedName = try titleLink?.text() ?? ""
                    
                    let components = href.components(separatedBy: "/")
                    guard components.count >= 5 else { return nil }
                    let id = components[2]
                    let pseudID = components[4]
                    
                    var profilePicture: AO3Image? = nil
                    if let imgElement = try element.select("div.icon img").first() {
                        let src = try imgElement.attr("src")
                        let alt = try imgElement.attr("alt")
                        if !src.isEmpty {
                            profilePicture = AO3Image(description: alt.isEmpty ? nil : alt, source: src.hasPrefix("http") ? src : "https://archiveofourown.org\(src)")
                        }
                    }
                    
                    let authorLink = AO3AuthorLink(id: id, pseudID: pseudID, displayedName: displayedName, profilePicture: profilePicture)
                    

                    var unblockActionID: Int? = nil
                    var unmuteActionID: Int? = nil

                    if let actionLink = try element.select("ul.actions a").first() {
                        let actionHref = try actionLink.attr("href")
                        
                        if let regex = try? NSRegularExpression(pattern: "/(\\d+)/confirm_(unblock|unmute)"),
                           let match = regex.firstMatch(in: actionHref, range: NSRange(actionHref.startIndex..., in: actionHref)) {
                            
                            if let idRange = Range(match.range(at: 1), in: actionHref),
                               let typeRange = Range(match.range(at: 2), in: actionHref) {
                                
                                let parsedID = Int(String(actionHref[idRange]))
                                let actionType = String(actionHref[typeRange])
                                
                                if actionType == "unblock" {
                                    unblockActionID = parsedID
                                } else if actionType == "unmute" {
                                    unmuteActionID = parsedID
                                }
                            }
                        }
                    }
                    
                    guard unblockActionID != nil || unmuteActionID != nil else { return nil }
                    
                    return AO3MutedBlockedLink(
                        authorLink: authorLink,
                        unmuteActionID: unmuteActionID,
                        unblockActionID: unblockActionID
                    )
                    
                } catch {
                    return nil
                }
            }
        }
    }
}
