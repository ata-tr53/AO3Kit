//
//  AO3NotificationsParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 3.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    // MARK: - Inbox Parser
    
    static func parseInbox(html: String) throws -> [AO3Notification] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer { doc.empty() }
            
            let commentElements = try doc.select("ol.comment.index > li.comment").array()
            
            return commentElements.compactMap { element in
                do {
                    // 1. Extract the TRUE Inbox ID from the checkbox (Required for POST actions)
                    guard let checkbox = try element.select("input[name='inbox_comments[]']").first(),
                          let inboxIdString = try? checkbox.attr("value"),
                          let inboxID = Int(inboxIdString) else {
                        return nil
                    }

                    
                    let isRead = element.hasClass("read")
                    let isRepliedTo = try !element.select("span.replied").isEmpty()
                    
                    let user: AO3CommenterType
                    
                    if element.hasClass("guest") {
                        let guestName = try element.select("h4.heading span:not(.role)").first()?.text() ?? "Guest"
                        user = .guest(name: guestName)
                    } else {
                        var registeredUser: AO3AuthorLink? = nil
                        
                        if let userLink = try element.select("h4.heading a[href*='/users/']").first() {
                            let href = try userLink.attr("href")
                            let name = try userLink.text()
                            
                            let components = href.components(separatedBy: "/")
                            if components.count >= 3 {
                                let userID = components[2].removingPercentEncoding ?? components[2]
                                let pseudID = (components.count >= 5 && components[3] == "pseuds") ? (components[4].removingPercentEncoding ?? components[4]) : userID
                                
                                var profilePic: AO3Image? = nil
                                if let img = try element.select("div.icon img.icon").first() {
                                    let src = try img.attr("src")
                                    profilePic = AO3Image(description: try img.attr("alt"), source: src.hasPrefix("http") ? src : "https://archiveofourown.org\(src)")
                                }
                                
                                registeredUser = AO3AuthorLink(id: userID, pseudID: pseudID, displayedName: name, profilePicture: profilePic)
                            }
                        }
                        
                        user = registeredUser != nil ? .registered(link: registeredUser!) : .guest(name: "Unknown User")
                    }
                    
                    guard let locationLink = try element.select("h4.heading a[href*='/comments/']").first() else {
                        throw AO3ClientError.invalidData
                    }
                    
                    let locationText = try locationLink.text()
                    let href = try locationLink.attr("href")
                    
                    var workID = 0
                    
                    let elementId = try element.attr("id")
                    var commentID = Int(elementId.replacingOccurrences(of: "feedback_comment_", with: "")) ?? 0
                    
                    let urlComponents = href.components(separatedBy: "/")
                    if let worksIndex = urlComponents.firstIndex(of: "works"), worksIndex + 1 < urlComponents.count {
                        workID = Int(urlComponents[worksIndex + 1]) ?? 0
                    }
                    if let commentsIndex = urlComponents.firstIndex(of: "comments"), commentsIndex + 1 < urlComponents.count {
                        commentID = Int(urlComponents[commentsIndex + 1]) ?? commentID
                    }
                    
                    var chapterIndex = 1
                    var workTitle = locationText
                    
                    if locationText.hasPrefix("Chapter "), let ofRange = locationText.range(of: " of ") {
                        let chapterPart = locationText[..<ofRange.lowerBound]
                        chapterIndex = Int(chapterPart.replacingOccurrences(of: "Chapter ", with: "")) ?? 1
                        workTitle = String(locationText[ofRange.upperBound...])
                    }
                    
                    let commentLocation = AO3CommentLink(
                        id: commentID,
                        workID: workID,
                        index: chapterIndex,
                        workTitle: workTitle
                    )
                    
                    let relativeDate = try element.select("span.posted.datetime").text()
                    let contentHTML = try element.select("blockquote.userstuff").html()
                    
                    return AO3Notification(
                        id: inboxID,
                        user: user,
                        commentLocation: commentLocation,
                        relativeDate: relativeDate,
                        contentHTML: contentHTML,
                        isRead: isRead,
                        isRepliedTo: isRepliedTo
                    )
                } catch {
                    print("⚠️ Failed to parse inbox comment: \(error)")
                    return nil
                }
            }
        }
    }

}
