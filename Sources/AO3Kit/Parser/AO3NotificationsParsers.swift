//
//  AO3NotificationsParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 3.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    static func parseInbox(html: String) throws -> [AO3Notification] {
        try parseElements(html: html, selector: "ol.comment.index > li.comment") { element in
            guard let inboxIdString = element.firstAttr("input[name='inbox_comments[]']", "value"),
                  let inboxID = Int(inboxIdString),
                  let locationLink = try element.select("h4.heading a[href*='/comments/']").first() else {
                return nil
            }
            
            let isRead = element.hasClass("read")
            let isRepliedTo = try !element.select("span.replied").isEmpty()
            
            let user: AO3CommenterType
            if element.hasClass("guest") {
                user = .guest(name: element.firstText("h4.heading span:not(.role)") ?? "Guest")
            } else {
                let profilePic = parseImage(from: try element.select("div.icon img.icon").first())
                if let registeredUser = parseAuthorLink(
                    from: try element.select("h4.heading a[href*='/users/']").first(),
                    profilePicture: profilePic
                ) {
                    user = .registered(link: registeredUser)
                } else {
                    user = .guest(name: "Unknown User")
                }
            }
            
            let locationText = try locationLink.text()
            let href = try locationLink.attr("href")
            let urlComponents = href.components(separatedBy: "/")
            
            var workID = 0
            if let worksIndex = urlComponents.firstIndex(of: "works"), worksIndex + 1 < urlComponents.count {
                workID = Int(urlComponents[worksIndex + 1]) ?? 0
            }
            
            var commentID = Int(try element.attr("id").replacingOccurrences(of: "feedback_comment_", with: "")) ?? 0
            if let commentsIndex = urlComponents.firstIndex(of: "comments"), commentsIndex + 1 < urlComponents.count {
                commentID = Int(urlComponents[commentsIndex + 1]) ?? commentID
            }
            
            var chapterIndex = 1
            var workTitle = locationText
            if locationText.hasPrefix("Chapter "), let ofRange = locationText.range(of: " of ") {
                chapterIndex = Int(locationText[..<ofRange.lowerBound].replacingOccurrences(of: "Chapter ", with: "")) ?? 1
                workTitle = String(locationText[ofRange.upperBound...])
            }
            
            return AO3Notification(
                id: inboxID,
                user: user,
                commentLocation: AO3CommentLink(id: commentID, workID: workID, index: chapterIndex, workTitle: workTitle),
                relativeDate: element.firstText("span.posted.datetime") ?? "",
                contentHTML: try element.select("blockquote.userstuff").html(),
                isRead: isRead,
                isRepliedTo: isRepliedTo
            )
        }
    }

}
