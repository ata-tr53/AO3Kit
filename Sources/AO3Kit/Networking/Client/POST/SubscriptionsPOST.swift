//
//  SubscriptionsPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 5.10.2026.
//

import Foundation
import SwiftData

public extension AO3Client {
    // MARK: - Subscription Management
    
    func toggleSubscription<Target: AO3Subscribable>(for username: String, target: Target) async throws {
        if target.isSubscribed {
            try await self.deleteSubscription(for: username, target: target)
        } else {
            try await self.addSubscription(for: username, target: target)
        }
    }
    
    func addSubscription<Target: AO3Subscribable>(for username: String, target: Target) async throws {
        try await self.addSubscription(for: username, targetID: target.subscribableID, targetType: target.responseType.rawValue)
        await cache.invalidate(containing: "\(target.subscribableID)")
    }
    
    func deleteSubscription<Target: AO3Subscribable>(for username: String, target: Target) async throws {
        guard let subscriptionID = target.subscriptionRecordID else { throw AO3ClientError.noSubscription }
        try await self.deleteSubscription(for: username, subscriptionID: subscriptionID)
        
        await cache.invalidate(containing: "\(target.subscribableID)")
    }
    
    func deleteSubscription(for username: String, target: AO3Subscription) async throws {
        try await self.deleteSubscription(for: username, subscriptionID: target.id)
    }
    
    /// Creates a new subscription for a given element.
    internal func addSubscription(for username: String, targetID: Int, targetType: String) async throws {
        let endpoint: AO3Endpoint = AO3Endpoint.user(username: username, route: .subscriptions)
        
        guard let indexURL = endpoint.url() else {
            throw AO3ClientError.invalidURL
        }
        
        let indexHTML = try await performRequest(url: indexURL, method: .get)
        let csrfToken = try AO3Parser.parseCSRFToken(from: indexHTML)
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "authenticity_token", value: csrfToken),
            URLQueryItem(name: "subscription[subscribable_id]", value: String(targetID)),
            URLQueryItem(name: "subscription[subscribable_type]", value: targetType)
        ]
        
        guard let postString = components.query, let postData = postString.data(using: .utf8) else {
            throw AO3ClientError.invalidData
        }
        
        let responseHTML = try await performRequest(url: indexURL, method: .post, body: postData)
        
        let successMessages = ["Successfully subscribed", "You are now following"]
        guard successMessages.contains(where: { responseHTML.contains($0) }) else {
            throw AO3ClientError.invalidData
        }
        
        await cache.invalidate(containing: username)
        await cache.invalidate(containing: "subscription")
    }
    
    internal func deleteSubscription(for username: String, subscriptionID: Int) async throws {
        let endpoint: AO3Endpoint = AO3Endpoint.user(username: username, route: .subscriptions)
        
        guard let indexURL = endpoint.url(),
              let actionURL = AO3Endpoint.user(username: username, route: .deleteSubscription(id: subscriptionID)).url() else {
            throw AO3ClientError.invalidURL
        }
        
        let indexHTML = try await performRequest(url: indexURL, method: .get)
        let csrfToken = try AO3Parser.parseCSRFToken(from: indexHTML)
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "_method", value: "delete"),
            URLQueryItem(name: "authenticity_token", value: csrfToken)
        ]
        
        guard let postString = components.query, let postData = postString.data(using: .utf8) else {
            throw AO3ClientError.invalidData
        }
        
        let responseHTML = try await performRequest(url: actionURL, method: .post, body: postData)
        
        guard responseHTML.contains("Successfully deleted subscription") || responseHTML.contains("Subscription deleted") else {
            if !responseHTML.contains("edit_subscription_\(subscriptionID)") {
                return
            }
            throw AO3ClientError.invalidData
        }
        
        await cache.invalidate(containing: username)
        await cache.invalidate(containing: "subscription")
    }

}
