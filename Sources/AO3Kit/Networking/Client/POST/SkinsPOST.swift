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
}
