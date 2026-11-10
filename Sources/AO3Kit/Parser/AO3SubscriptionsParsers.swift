//
//  AO3Subscriptions.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 5.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    static func parseSubscriptions(html: String) throws -> [AO3Subscription] {
        try withDocument(html: html) { doc in
            let dtElements = try doc.select("dl.subscription.index.group > dt").array()
            
            return try dtElements.compactMap { dt in
                guard let dd = try dt.nextElementSibling(), dd.tagName() == "dd",
                      let formIdAttr = dd.firstAttr("form.edit_subscription", "id"),
                      let subscriptionID = Int(formIdAttr.replacingOccurrences(of: "edit_subscription_", with: "")),
                      let mainLink = try dt.select("a").first() else {
                    return nil
                }
                
                let targetName = try mainLink.text()
                let href = try mainLink.attr("href")
                let authors = parseAuthorLinks(in: dt, selector: "a[rel=author]")
                
                let target: AO3SubscriptionType
                if href.hasPrefix("/users/"), let userLink = parseAuthorLink(from: mainLink) {
                    target = .user(link: userLink)
                } else if href.hasPrefix("/works/") {
                    let workID = Int(href.replacingOccurrences(of: "/works/", with: "").components(separatedBy: "/").first ?? "") ?? 0
                    target = .work(id: workID, authors: authors)
                } else if href.hasPrefix("/series/") {
                    let seriesID = Int(href.replacingOccurrences(of: "/series/", with: "").components(separatedBy: "/").first ?? "") ?? 0
                    target = .series(id: seriesID, creators: authors)
                } else {
                    return nil
                }
                
                return AO3Subscription(id: subscriptionID, name: targetName, type: target)
            }
        }
    }
    
    // MARK: - Active Subscription ID Extraction
    
    internal static func parseSubscriptionID(from document: Document) throws -> Int? {
        guard let subscriptionForm = try document.select("form:has(input[name=subscription[subscribable_id]])").first() else {
            return nil
        }
        
        let submitValue = subscriptionForm.firstAttr("input[type=submit]", "value")?.lowercased()
        guard submitValue == "unsubscribe" else {
            return nil
        }
        
        // 1. Try extracting ID from the form's id attribute (e.g., id="edit_subscription_123456")
        if let formId = try? subscriptionForm.attr("id"),
           let match = formId.range(of: #"\d+"#, options: .regularExpression),
           let id = Int(formId[match]) {
            return id
        }
        
        // 2. Fallback to extracting the trailing ID from the form's action URL (e.g., /users/{username}/subscriptions/123456)
        if let actionUrl = try? subscriptionForm.attr("action"),
           let lastComponent = actionUrl.split(separator: "/").last,
           let id = Int(lastComponent) {
            return id
        }
        
        return nil
    }
    
}
