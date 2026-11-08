//
//  NotificationsPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 3.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Client {
    
    // MARK: - Inbox Management
    
    func manageInbox(for username: String, commentIDs: [Int], action: AO3InboxAction) async throws {
        guard !commentIDs.isEmpty else { return }
        
        guard let inboxURL = AO3Endpoint.user(username: username, route: .inbox).url() else {
            throw AO3ClientError.invalidURL
        }
        
        let inboxHTML = try await performRequest(url: inboxURL, method: .get)
        let csrfToken = try AO3Parser.parseCSRFToken(from: inboxHTML)
        
        var queryItems = [
            URLQueryItem(name: "utf8", value: "✓"),
            URLQueryItem(name: "_method", value: "put"),
            URLQueryItem(name: "authenticity_token", value: csrfToken),
            URLQueryItem(name: action.rawValue, value: action.buttonValue)
        ]

        for id in commentIDs {
            queryItems.append(URLQueryItem(name: "inbox_comments[]", value: String(id)))
        }

        let responseHTML = try await performFormPost(
            url: inboxURL,
            formItems: queryItems,
            referer: inboxURL
        )
        
        guard responseHTML.contains("Inbox successfully updated") || responseHTML.contains("Item(s) deleted") else {
            throw AO3ClientError.invalidData
        }
        
        
        await cache.invalidate(containing: "inbox")
    }
}

public enum AO3InboxAction: String, Sendable {
    case markRead = "read"
    case markUnread = "unread"
    case delete = "delete"
    
    var buttonValue: String {
        switch self {
        case .markRead: return "Mark Read"
        case .markUnread: return "Mark Unread"
        case .delete: return "Delete From Inbox"
        }
    }
}

