//
//  FavoriteTagsPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

internal extension AO3Client {

    func fetchFavoriteTags(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FavoriteTag] {
        let username = try await resolveCurrentUsername()
        guard let homeURL = AO3Endpoint.home.url() else {
            throw AO3ClientError.invalidURL
        }

        return try await fetchCachedItem(
            url: homeURL,
            cacheKey: "favorite_tags_\(username)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseFavoriteTags(html: html)
        }
    }

    func addFavoriteTag(named tagName: String) async throws {
        let username = try await resolveCurrentUsername()
        guard let tagURL = AO3Endpoint.tag(name: tagName, route: .works).url(),
              let postURL = AO3Endpoint.user(username: username, route: .favoriteTags).url() else {
            throw AO3ClientError.invalidURL
        }

        let pageHTML = try await performRequest(url: tagURL, method: .get)
        let context = try AO3Parser.parseFavoriteTagActionContext(from: pageHTML)

        // Already favorited
        if context.favoriteTagRecordID != nil {
            return
        }

        guard let tagID = context.tagID else {
            throw AO3ClientError.invalidData
        }

        let responseHTML = try await performFormPost(
            url: postURL,
            formItems: [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: context.csrfToken),
                URLQueryItem(name: "favorite_tag[tag_id]", value: String(tagID)),
                URLQueryItem(name: "commit", value: "Favorite Tag")
            ],
            referer: tagURL
        )

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "favorite_tags")
    }

    func removeFavoriteTag(named tagName: String) async throws {
        let username = try await resolveCurrentUsername()
        guard let tagURL = AO3Endpoint.tag(name: tagName, route: .works).url() else {
            throw AO3ClientError.invalidURL
        }

        let pageHTML = try await performRequest(url: tagURL, method: .get)
        let context = try AO3Parser.parseFavoriteTagActionContext(from: pageHTML)

        guard let recordID = context.favoriteTagRecordID else {
            throw AO3ClientError.noDataFound
        }

        try await removeFavoriteTag(recordID: recordID, username: username, csrfToken: context.csrfToken, referer: tagURL)
    }

    func removeFavoriteTag(recordID: Int) async throws {
        let username = try await resolveCurrentUsername()
        guard let homeURL = AO3Endpoint.home.url(),
              let deleteURL = AO3Endpoint.user(username: username, route: .deleteFavoriteTag(id: recordID)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: deleteURL,
            tokenFallbackURL: homeURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "favorite_tags")
    }

    private func removeFavoriteTag(
        recordID: Int,
        username: String,
        csrfToken: String,
        referer: URL
    ) async throws {
        guard let deleteURL = AO3Endpoint.user(username: username, route: .deleteFavoriteTag(id: recordID)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performFormPost(
            url: deleteURL,
            formItems: [
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ],
            referer: referer
        )

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "favorite_tags")
    }
}
