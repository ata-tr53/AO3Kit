//
//  PreferencesPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

internal extension AO3Client {

    func fetchUserPreferences(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3UserPreferences {
        let username = try await resolveCurrentUsername()
        return try await fetchCachedItem(
            endpoint: .user(username: username, route: .preferences),
            cacheKey: "user_preferences_\(username)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseUserPreferences(html: html)
        }
    }

    func updateUserPreferences(_ preferences: AO3UserPreferences) async throws {
        let username = try await resolveCurrentUsername()
        guard let indexURL = AO3Endpoint.user(username: username, route: .preferences).url(),
              let updateURL = AO3Endpoint.user(username: username, route: .preferences(id: preferences.preferenceID)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: updateURL,
            tokenFallbackURL: indexURL
        ) { csrfToken in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
            items.append(contentsOf: preferences.toFormItems())
            items.append(URLQueryItem(name: "commit", value: "Update"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "user_preferences_\(username)")
        await cache.invalidate(containing: "preferences")
    }
}
