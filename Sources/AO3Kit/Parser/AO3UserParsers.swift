//
//  AO3UserParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - Current User Parser
    
    static func parseCurrentUser(from html: String) throws -> AO3AuthorLink {
        try withDocument(html: html) { doc in
            let profilePicture = parseImage(from: try doc.select("nav#greeting p.icon img.icon").first())
            guard let linkElement = try doc.select("nav#greeting ul.user.navigation a[href^='/users/']").first(),
                  let href = try? linkElement.attr("href") else {
                throw AO3ClientError.requiresRegistration
            }
            let components = href.components(separatedBy: "/")
            guard components.count >= 3, components[1] == "users" else {
                throw AO3ClientError.invalidData
            }
            let username = components[2].removingPercentEncoding ?? components[2]
            return AO3AuthorLink(
                id: username,
                pseudID: username,
                displayedName: username,
                profilePicture: profilePicture
            )
        }
    }
    
    // MARK: - User Profile Parser
    
    static func parseUserProfile(html: String, username: String) throws -> AO3AuthorMetadata {
        try withDocument(html: html) { doc in
            let userID = doc.firstInt("dl.meta dt:contains(My user ID is:) + dd") ?? 0
            let profilePic = parseImage(from: try doc.select("img.icon").first())
                ?? AO3Image(description: nil, source: "")
            let pseuds = doc.texts("dd.pseuds a")
            let joinDate = DateFormatter.ao3DateFormatter.date(
                from: doc.firstText("dl.meta dt:contains(I joined on:) + dd") ?? ""
            ) ?? Date()
            let biography = extractText(from: try doc.select("blockquote.userstuff").first())
            
            let parenRegex = try? NSRegularExpression(pattern: #"\(([\d,]+)\)"#)
            let navTexts = doc.texts("div#dashboard ul.navigation.actions li")
            func parseStat(label: String) -> Int {
                guard let line = navTexts.first(where: { $0.hasPrefix(label + " (") }),
                      let match = parenRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                      let range = Range(match.range(at: 1), in: line) else { return 0 }
                return parseInt(String(line[range])) ?? 0
            }
            
            var signedInMetadata: AO3AuthorMetadata.AO3SignedInUserMetadata? = nil
            let isOwnDashboard = try !doc.select("div#dashboard.own").isEmpty() || !doc.select("div#dashboard li:contains(Inbox)").isEmpty()
            if isOwnDashboard {
                signedInMetadata = AO3AuthorMetadata.AO3SignedInUserMetadata(
                    id: userID,
                    inboxCount: parseStat(label: "Inbox"),
                    signupCount: parseStat(label: "Sign-ups"),
                    assignmentsCount: parseStat(label: "Assignments"),
                    claimsCount: parseStat(label: "Claims"),
                    relatedWorksCount: parseStat(label: "Related Works")
                )
            }
            
            let (unblockActionID, unmuteActionID) = parseModerationActionIDs(in: doc, selector: "ul.navigation.actions li a")
            
            return AO3AuthorMetadata(
                id: userID,
                username: username,
                profilePicture: profilePic,
                pseuds: pseuds,
                joinDate: joinDate,
                biography: biography,
                workCount: parseStat(label: "Works"),
                seriesCount: parseStat(label: "Series"),
                bookmarkCount: parseStat(label: "Bookmarks"),
                collectionCount: parseStat(label: "Collections"),
                giftsCount: parseStat(label: "Gifts"),
                signedInMetadata: signedInMetadata,
                subscriptionRecordID: try parseSubscriptionID(from: doc),
                unblockActionID: unblockActionID,
                unmuteActionID: unmuteActionID
            )
        }
    }
    
    // MARK: - Pseud Parser
    
    /// /users/[id]/pseuds
    static func parseUserPseuds(html: String) throws -> [AO3AuthorPseudLink] {
        try parseElements(html: html, selector: "li.user.pseud.picture.blurb.group") { element in
            guard let nameLink = try element.select("h4.heading a[href*='/pseuds/']").first(),
                  let authorLink = parseAuthorLink(from: nameLink) else {
                return nil
            }
            let workCountText = element.firstText("h5.heading a[href$='/works']")?.replacingOccurrences(of: " works", with: "")
            return AO3AuthorPseudLink(
                username: authorLink.id,
                pseudName: authorLink.displayedName,
                summary: try element.select("blockquote.userstuff").first()?.html(),
                icon: parseImage(from: try element.select("div.icon img.icon").first()),
                workCount: parseInt(workCountText)
            )
        }
    }
    
    internal static func parsePseudIDs(from html: String) throws -> [String: Int] {
        try withDocument(html: html) { doc in
            var pseudMap: [String: Int] = [:]
            for option in try doc.select("select[name='comment[pseud_id]'] option").array() {
                let name = try option.text()
                if let id = Int(try option.attr("value")) {
                    pseudMap[name] = id
                }
            }
            return pseudMap
        }
    }
    
    internal static func parseModerationActionIDs(in container: Element, selector: String) -> (unblockID: Int?, unmuteID: Int?) {
        guard let links = try? container.select(selector).array(),
              let regex = try? NSRegularExpression(pattern: #"/(\d+)/confirm_(unblock|unmute)"#) else {
            return (nil, nil)
        }
        var unblockID: Int? = nil
        var unmuteID: Int? = nil
        
        for link in links {
            guard let href = try? link.attr("href"),
                  let match = regex.firstMatch(in: href, range: NSRange(href.startIndex..., in: href)),
                  let idRange = Range(match.range(at: 1), in: href),
                  let typeRange = Range(match.range(at: 2), in: href) else { continue }
            
            let parsedID = Int(href[idRange])
            if href[typeRange] == "unblock" {
                unblockID = parsedID
            } else if href[typeRange] == "unmute" {
                unmuteID = parsedID
            }
        }
        return (unblockID, unmuteID)
    }
    
}
