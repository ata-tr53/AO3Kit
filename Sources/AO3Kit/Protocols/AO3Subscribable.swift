//
//  AO3Subscribable.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 5.10.2026.
//

import SwiftSoup
import Foundation

public protocol AO3Subscribable: AO3Response {
    var subscribableID: Int { get }
    
    var subscriptionRecordID: Int? { get set }
}

public extension AO3Subscribable {
    var isSubscribed: Bool {
        return self.subscriptionRecordID != nil
    }
}

public extension AO3Parser {
    
    /// Extracts the active subscription record ID from a parsed document, if the user is currently subscribed.
    internal static func parseSubscriptionID(from document: Document) throws -> Int? {
        guard let subscriptionForm = try document.select("form:has(input[name=subscription[subscribable_id]])").first() else {
            return nil
        }
        
        let submitValue = try subscriptionForm.select("input[type=submit]").first()?
            .attr("value")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard submitValue == "unsubscribe" else {
            return nil
        }
        
        let formId = try subscriptionForm.attr("id")
        if let regex = try? NSRegularExpression(pattern: "\\d+"),
           let match = regex.firstMatch(in: formId, range: NSRange(formId.startIndex..., in: formId)),
           let range = Range(match.range, in: formId),
           let id = Int(String(formId[range])) {
            return id
        }
        
        let actionUrl = try subscriptionForm.attr("action")
        if let lastComponent = actionUrl.split(separator: "/").last,
           let id = Int(String(lastComponent)) {
            return id
        }
        
        return nil
    }
}
