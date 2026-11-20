//
//  DashboardPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

internal extension AO3Client {

    // MARK: - Related Works

    func fetchRelatedWorks(
        for username: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3RelatedWork] {
        try await fetchCachedItem(
            endpoint: .user(username: username, route: .relatedWorks(.index)),
            cacheKey: "related_works_\(username)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseRelatedWorks(html: html)
        }
    }

    func approveRelatedWork(id relatedWorkID: Int) async throws {
        let username = try await resolveCurrentUsername()
        guard let listURL = AO3Endpoint.user(username: username, route: .relatedWorks(.index)).url(),
              let itemURL = AO3Endpoint.relatedWork(.show(id: relatedWorkID)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: itemURL,
            tokenFallbackURL: listURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "commit", value: "Yes, link me!")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "related_works")
    }

    func removeRelatedWork(id relatedWorkID: Int) async throws {
        let username = try await resolveCurrentUsername()
        guard let listURL = AO3Endpoint.user(username: username, route: .relatedWorks(.index)).url(),
              let itemURL = AO3Endpoint.relatedWork(.show(id: relatedWorkID)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: itemURL,
            tokenFallbackURL: listURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "related_works")
    }

    // MARK: - Co-Creator Requests (Creatorships)

    func fetchCoCreatorRequests(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3CoCreatorRequest] {
        let username = try await resolveCurrentUsername()
        return try await fetchCachedItem(
            endpoint: .user(username: username, route: .creatorships),
            cacheKey: "creatorships_\(username)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseCoCreatorRequests(html: html)
        }
    }

    func respondToCoCreatorRequests(ids: [Int], accept: Bool) async throws {
        guard !ids.isEmpty else { return }
        let username = try await resolveCurrentUsername()
        guard let creatorshipsURL = AO3Endpoint.user(username: username, route: .creatorships).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: creatorshipsURL,
            tokenFallbackURL: creatorshipsURL
        ) { csrfToken in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
            for id in ids {
                items.append(URLQueryItem(name: "selected[]", value: String(id)))
            }
            items.append(URLQueryItem(name: accept ? "accept" : "reject", value: accept ? "Accept" : "Reject"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "creatorships")
    }
}
