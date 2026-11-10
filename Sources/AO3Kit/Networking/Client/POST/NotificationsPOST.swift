//
//  NotificationsPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 3.10.2026.
//

import Foundation

internal extension AO3Client {
    
    // MARK: - Inbox Management
    
    func manageInbox(commentIDs: [Int], action: AO3InboxAction) async throws {
        guard !commentIDs.isEmpty else { return }
        let username = try await resolveCurrentUsername()
        
        guard let inboxURL = AO3Endpoint.user(username: username, route: .inbox).url() else {
            throw AO3ClientError.invalidURL
        }
        
        let responseHTML = try await performAuthenticatedFormPost(
            url: inboxURL,
            tokenFallbackURL: inboxURL
        ) { csrfToken in
            var queryItems = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "_method", value: "put"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: action.rawValue, value: action.buttonValue)
            ]
            for id in commentIDs {
                queryItems.append(URLQueryItem(name: "inbox_comments[]", value: String(id)))
            }
            return queryItems
        }
        
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
