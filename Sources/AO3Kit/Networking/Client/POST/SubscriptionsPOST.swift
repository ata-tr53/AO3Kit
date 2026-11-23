//
//  SubscriptionsPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 5.10.2026.
//

import Foundation

internal extension AO3Client {
    // MARK: - Subscription Management
    
    func toggleSubscription<Target: AO3Subscribable>(for target: Target) async throws {
        if target.isSubscribed {
            try await self.deleteSubscription(for: target)
        } else {
            try await self.addSubscription(for: target)
        }
    }

    func addSubscription<Target: AO3Subscribable>(for target: Target) async throws {
        let username = try await resolveCurrentUsername()
        try await self.addSubscription(for: username, targetID: target.subscribableID, targetType: target.responseType.rawValue)
        await cache.invalidate(containing: "\(target.subscribableID)")
    }

    func deleteSubscription<Target: AO3Subscribable>(for target: Target) async throws {
        guard let subscriptionID = target.subscriptionRecordID else { throw AO3ClientError.noSubscription }
        let username = try await resolveCurrentUsername()
        try await self.deleteSubscription(for: username, subscriptionID: subscriptionID)
        await cache.invalidate(containing: "\(target.subscribableID)")
    }

    func deleteSubscription(for target: AO3Subscription) async throws {
        let username = try await resolveCurrentUsername()
        try await self.deleteSubscription(for: username, subscriptionID: target.id)
    }
    
    /// Creates a new subscription for a given element.
    private func addSubscription(for username: String, targetID: Int, targetType: String) async throws {
        guard let indexURL = AO3Endpoint.user(username: username, route: .subscriptions).url() else {
            throw AO3ClientError.invalidURL
        }
        
        let responseHTML = try await performAuthenticatedFormPost(
            url: indexURL,
            tokenFallbackURL: indexURL
        ) { csrfToken in
            [
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "subscription[subscribable_id]", value: String(targetID)),
                URLQueryItem(name: "subscription[subscribable_type]", value: targetType)
            ]
        }
        
        let successMessages = ["Successfully subscribed", "You are now following"]
        guard successMessages.contains(where: { responseHTML.contains($0) }) else {
            throw AO3ClientError.invalidData
        }
        
        await cache.invalidate(containing: username)
        await cache.invalidate(containing: "subscription")
    }
    
    private func deleteSubscription(for username: String, subscriptionID: Int) async throws {
        guard let indexURL = AO3Endpoint.user(username: username, route: .subscriptions).url(),
              let actionURL = AO3Endpoint.user(username: username, route: .deleteSubscription(id: subscriptionID)).url() else {
            throw AO3ClientError.invalidURL
        }
        
        let responseHTML = try await performAuthenticatedFormPost(
            url: actionURL,
            tokenFallbackURL: indexURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }
        
        guard responseHTML.contains("Successfully deleted subscription") || responseHTML.contains("Subscription deleted") else {
            if !responseHTML.contains("edit_subscription_\(subscriptionID)") {
                return
            }
            throw AO3ClientError.invalidData
        }
        
        await cache.invalidate(containing: username)
        await cache.invalidate(containing: "subscription")
    }

    /// Deletes all subscriptions for the currently authenticated user (`POST /users/:username/subscriptions/delete_all`).
    func deleteAllSubscriptions() async throws {
        let username = try await resolveCurrentUsername()
        guard let confirmURL = AO3Endpoint.user(username: username, route: .confirmDeleteAllSubscriptions).url(),
              let deleteAllURL = AO3Endpoint.user(username: username, route: .deleteAllSubscriptions).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: deleteAllURL,
            tokenFallbackURL: confirmURL
        ) { csrfToken in
            [
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: username)
        await cache.invalidate(containing: "subscription")
    }
}
