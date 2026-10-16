//
//  AO3Subscriptions.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 5.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    // MARK: - Subscriptions Parser
    
    static func parseSubscriptions(html: String) throws -> [AO3Subscription] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            var subscriptions: [AO3Subscription] = []
            
            let dtElements = try doc.select("dl.subscription.index.group > dt").array()
            
            for dt in dtElements {
                guard let dd = try dt.nextElementSibling(), dd.tagName() == "dd" else { continue }
                
                guard let form = try dd.select("form.edit_subscription").first(),
                      let formIdAttr = try? form.attr("id") else { continue }
                
                let idString = formIdAttr.replacingOccurrences(of: "edit_subscription_", with: "")
                guard let subscriptionID = Int(idString) else { continue }
                
                guard let mainLink = try dt.select("a").first() else { continue }
                let targetName = try mainLink.text()
                let href = try mainLink.attr("href")
                
                var authors: [AO3AuthorLink] = []
                let authorLinks = try dt.select("a[rel=author]").array()
                
                for authorLink in authorLinks {
                    let authorName = try authorLink.text()
                    let authorHref = try authorLink.attr("href")
                    
                    let components = authorHref.components(separatedBy: "/")
                    var userID = authorName
                    var pseudID = authorName
                    
                    if components.count >= 3 && components[1] == "users" {
                        userID = components[2].removingPercentEncoding ?? components[2]
                        if components.count >= 5 && components[3] == "pseuds" {
                            pseudID = components[4].removingPercentEncoding ?? components[4]
                        } else {
                            pseudID = userID
                        }
                    }
                    
                    authors.append(AO3AuthorLink(
                        id: userID,
                        pseudID: pseudID,
                        displayedName: authorName,
                        profilePicture: nil
                    ))
                }
                
                let target: AO3SubscriptionType
                if href.hasPrefix("/users/") {
                    let username = href.replacingOccurrences(of: "/users/", with: "").components(separatedBy: "/").first ?? targetName
                    
                    let userLink = AO3AuthorLink(
                        id: username,
                        pseudID: username,
                        displayedName: targetName,
                        profilePicture: nil
                    )
                    target = .user(link: userLink)
                    
                } else if href.hasPrefix("/works/") {
                    let workIDString = href.replacingOccurrences(of: "/works/", with: "").components(separatedBy: "/").first ?? "0"
                    target = .work(id: Int(workIDString) ?? 0, authors: authors)
                    
                } else if href.hasPrefix("/series/") {
                    let seriesIDString = href.replacingOccurrences(of: "/series/", with: "").components(separatedBy: "/").first ?? "0"
                    target = .series(id: Int(seriesIDString) ?? 0, creators: authors)
                    
                } else {
                    continue
                }
                
                subscriptions.append(AO3Subscription(
                    id: subscriptionID,
                    name: targetName,
                    type: target
                ))
            }
            
            return subscriptions
        }
    }
    
}
