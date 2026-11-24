//
//  SkinsPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

internal extension AO3Client {

    func fetchPublicSkinsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3Skin> {
        try await fetchPaginated(
            endpoint: .skin(.index),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseSkins
        )
    }

    func fetchAllPublicSkins(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3Skin] {
        try await fetchAllItems(
            endpoint: .skin(.index),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseSkins
        )
    }

    func fetchUserSkinsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3Skin> {
        let username = try await resolveCurrentUsername()
        return try await fetchPaginated(
            endpoint: .user(username: username, route: .skins),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseSkins
        )
    }

    func fetchAllUserSkins(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3Skin] {
        let username = try await resolveCurrentUsername()
        return try await fetchAllItems(
            endpoint: .user(username: username, route: .skins),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseSkins
        )
    }

    func setSkin(id skinID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let skinsURL = AO3Endpoint.skin(.index).url(),
              let setURL = AO3Endpoint.skin(.set(id: skinID)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: setURL,
            tokenFallbackURL: skinsURL
        ) { csrfToken in
            [
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "skins")
    }

    func unsetSkin() async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let skinsURL = AO3Endpoint.skin(.index).url(),
              let unsetURL = AO3Endpoint.skin(.unset).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: unsetURL,
            tokenFallbackURL: skinsURL
        ) { csrfToken in
            [
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "skins")
    }

    func fetchSkinDetails(
        id skinID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3SkinDetails {
        try await fetchCachedItem(
            endpoint: .skin(.show(id: skinID)),
            cacheKey: "skin_details_\(skinID)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseSkinDetails(html: html, id: skinID)
        }
    }

    func previewSkin(id skinID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let previewURL = AO3Endpoint.skin(.preview(id: skinID)).url() else {
            throw AO3ClientError.invalidURL
        }
        _ = try await performRequest(url: previewURL)
    }

    @discardableResult
    func createSkin(_ draft: AO3SkinDraft) async throws -> Int? {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let newURL = AO3Endpoint.skin(.new).url(),
              let postURL = AO3Endpoint.skin(.index).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: newURL
        ) { csrfToken in
            buildSkinFormItems(draft: draft, csrfToken: csrfToken, isEditing: false)
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "skins")
        return try? AO3Parser.parseSkinIDFromResponse(html: responseHTML)
    }

    func updateSkin(id skinID: Int, draft: AO3SkinDraft) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let editURL = AO3Endpoint.skin(.edit(id: skinID)).url(),
              let updateURL = AO3Endpoint.skin(.show(id: skinID)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: updateURL,
            tokenFallbackURL: editURL
        ) { csrfToken in
            buildSkinFormItems(draft: draft, csrfToken: csrfToken, isEditing: true)
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "skins")
        await cache.invalidate(containing: "skin_details_\(skinID)")
    }

    func deleteSkin(id skinID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let confirmURL = AO3Endpoint.skin(.confirmDelete(id: skinID)).url(),
              let skinURL = AO3Endpoint.skin(.show(id: skinID)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: skinURL,
            tokenFallbackURL: confirmURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "skins")
        await cache.invalidate(containing: "skin_details_\(skinID)")
    }

    private func buildSkinFormItems(
        draft: AO3SkinDraft,
        csrfToken: String,
        isEditing: Bool
    ) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "utf8", value: "✓"),
            URLQueryItem(name: "authenticity_token", value: csrfToken),
            URLQueryItem(name: "skin[type]", value: draft.type == .work ? "WorkSkin" : "Skin"),
            URLQueryItem(name: "skin[title]", value: draft.title),
            URLQueryItem(name: "skin[description]", value: draft.description),
            URLQueryItem(name: "skin[css]", value: draft.css),
            URLQueryItem(name: "skin[public]", value: draft.isPublic ? "1" : "0"),
            URLQueryItem(name: "skin[role]", value: draft.role)
        ]

        if isEditing {
            items.insert(URLQueryItem(name: "_method", value: "patch"), at: 1)
        }

        for media in draft.media {
            items.append(URLQueryItem(name: "skin[media][]", value: media))
        }

        for (index, parentTitle) in draft.parentSkinTitles.enumerated() {
            items.append(URLQueryItem(
                name: "skin[skin_parents_attributes][\(index)][parent_skin_title]",
                value: parentTitle
            ))
            items.append(URLQueryItem(
                name: "skin[skin_parents_attributes][\(index)][position]",
                value: String(index + 1)
            ))
        }

        items.append(URLQueryItem(name: "commit", value: isEditing ? "Update" : "Submit"))
        return items
    }
}
