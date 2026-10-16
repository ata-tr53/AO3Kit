//
//  AO3UserParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - User Profile Parser
    
    static func parseUserProfile(html: String, username: String) throws -> AO3AuthorMetadata {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer {
                doc.empty()
            }
            
            let userIDText = try doc.select("dl.meta dt:contains(My user ID is:) + dd").first()?.text() ?? ""
            let userID = Int(userIDText.trimmingCharacters(in: .whitespaces)) ?? 0
            
            var profilePic = AO3Image(description: nil, source: "")
            
            if let imgElement = try doc.select("img.icon").first() {
                profilePic.source = try imgElement.attr("src")
                let altText = try imgElement.attr("alt")
                if !altText.isEmpty {
                    profilePic.description = altText
                }
            }
            
            let pseuds = try doc.select("dd.pseuds a").array().map { try $0.text() }
            
            let joinDateText = try doc.select("dl.meta dt:contains(I joined on:) + dd").first()?.text() ?? ""
            let joinDate = DateFormatter.ao3DateFormatter.date(from: joinDateText) ?? Date()
            
            let bioElements = try doc.select("blockquote.userstuff p").array()
            let biography: String?
            
            if !bioElements.isEmpty {
                biography = try bioElements.compactMap { try $0.text() }.joined(separator: "\n\n")
            } else {
                biography = try doc.select("blockquote.userstuff").first()?.text()
            }
            
            func parseStat(label: String) -> Int {
                do {
                    let listItems = try doc.select("div#dashboard ul.navigation.actions li").array()
                    for li in listItems {
                        let text = try li.text()
                        
                        if text.hasPrefix(label + " (") {
                            if let regex = try? NSRegularExpression(pattern: "\\(([\\d,]+)\\)", options: []),
                               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                               let range = Range(match.range(at: 1), in: text) {
                                return Int(String(text[range]).replacingOccurrences(of: ",", with: "")) ?? 0
                            }
                        }
                    }
                } catch { return 0 }
                return 0
            }

            let workCount = parseStat(label: "Works")
            let seriesCount = parseStat(label: "Series")
            let bookmarkCount = parseStat(label: "Bookmarks")
            let collectionCount = parseStat(label: "Collections")
            let giftCount = parseStat(label: "Gifts")
            
            var signedInMetadata: AO3AuthorMetadata.AO3SignedInUserMetadata? = nil
            
            let isOwnDashboard = try !(try doc.select("div#dashboard.own").isEmpty()) || !(try doc.select("div#dashboard li:contains(Inbox)").isEmpty())
            
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
            
            let subscriptionRecordID = try parseSubscriptionID(from: doc)

            var unblockActionID: Int? = nil
            var unmuteActionID: Int? = nil

            if let actionLinks = try? doc.select("ul.navigation.actions li a").array() {
                let regex = try? NSRegularExpression(pattern: "/(\\d+)/confirm_(unblock|unmute)")
                
                for link in actionLinks {
                    let linkText = try link.text().trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let href = try link.attr("href")
                    
                    if linkText == "unblock" {
                        if let match = regex?.firstMatch(in: href, range: NSRange(href.startIndex..., in: href)),
                           let range = Range(match.range(at: 1), in: href) {
                            unblockActionID = Int(String(href[range]))
                        }
                    } else if linkText == "unmute" {
                        if let match = regex?.firstMatch(in: href, range: NSRange(href.startIndex..., in: href)),
                           let range = Range(match.range(at: 1), in: href) {
                            unmuteActionID = Int(String(href[range]))
                        }
                    }
                }
            }
            
            return AO3AuthorMetadata(
                id: userID,
                username: username,
                profilePicture: profilePic,
                pseuds: pseuds,
                joinDate: joinDate,
                biography: biography,
                workCount: workCount,
                seriesCount: seriesCount,
                bookmarkCount: bookmarkCount,
                collectionCount: collectionCount,
                giftsCount: giftCount,
                signedInMetadata: signedInMetadata,
                subscriptionRecordID: subscriptionRecordID,
                unblockActionID: unblockActionID,
                unmuteActionID: unmuteActionID
            )
        }
    }

    
    // MARK: - Pseud Parser
    
    /// /users/[id]/pseuds
    static func parseUserPseuds(html: String) throws -> [AO3AuthorPseudLink] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            let blurbElements = try doc.select("li.user.pseud.picture.blurb.group").array()
            
            return blurbElements.compactMap { element in
                do {
                    guard let nameLink = try element.select("h4.heading a[href*='/pseuds/']").first() else {
                        return nil
                    }
                    let pseudName = try nameLink.text()
                    
                    var workCount: Int? = nil
                    if let countLink = try element.select("h5.heading a[href$='/works']").first() {
                        let text = try countLink.text()
                            .replacingOccurrences(of: " works", with: "")
                            .replacingOccurrences(of: ",", with: "")
                        workCount = Int(text)
                    }
                    
                    var icon: AO3Image? = nil
                    if let imgElement = try element.select("div.icon img.icon").first() {
                        let src = try imgElement.attr("src")
                        let alt = try imgElement.attr("alt")
                        
                        if !src.isEmpty {
                            let fullURL = src.hasPrefix("http") ? src : "https://archiveofourown.org\(src)"
                            icon = AO3Image(
                                description: alt.isEmpty ? nil : alt,
                                source: fullURL
                            )
                        }
                    }
                    
                    let summaryHTML = try element.select("blockquote.userstuff").first()?.html()
                    
                    return AO3AuthorPseudLink(
                        pseudName: pseudName,
                        summary: summaryHTML,
                        icon: icon,
                        workCount: workCount
                    )
                } catch {
                    print("⚠️ Failed to parse pseud blurb: \(error)")
                    return nil
                }
            }
        }
    }
    
}
