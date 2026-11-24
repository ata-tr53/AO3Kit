//
//  CollectionsPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 24.11.2026.
//

import Foundation

internal extension AO3Client {

    func joinCollection(id collectionID: String) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let collectionURL = AO3Endpoint.collection(name: collectionID, route: .main).url(),
              let joinURL = AO3Endpoint.collection(name: collectionID, route: .participants(.join)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: joinURL,
            tokenFallbackURL: collectionURL
        ) { csrfToken in
            [URLQueryItem(name: "authenticity_token", value: csrfToken)]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: collectionID)
    }

    func leaveCollection(id collectionID: String) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let collectionURL = AO3Endpoint.collection(name: collectionID, route: .main).url() else {
            throw AO3ClientError.invalidURL
        }

        let html = try await performRequest(url: collectionURL)
        let csrfToken = try AO3Parser.parseCSRFToken(from: html)
        guard let participantID = try AO3Parser.parseCollectionLeaveParticipantID(from: html),
              let leaveURL = AO3Endpoint.collection(name: collectionID, route: .participants(.item(id: participantID))).url() else {
            throw AO3ClientError.invalidData
        }

        let responseHTML = try await performFormPost(
            url: leaveURL,
            formItems: [
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ],
            referer: collectionURL
        )

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: collectionID)
    }

    // MARK: - Collection Items Management

    func addWorkToCollections(workID: Int, collectionNames: [String]) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard !collectionNames.isEmpty else { return }
        guard let newURL = AO3Endpoint.work(id: workID, route: .collectionItems(.new)).url(),
              let postURL = AO3Endpoint.work(id: workID, route: .collectionItems(.index)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: newURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "collection_names", value: collectionNames.joined(separator: ", ")),
                URLQueryItem(name: "commit", value: "Add")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
    }

    func addBookmarkToCollections(bookmarkID: Int, collectionNames: [String]) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard !collectionNames.isEmpty else { return }
        guard let newURL = AO3Endpoint.bookmarks(.collectionItems(bookmarkID: bookmarkID, action: .new)).url(),
              let postURL = AO3Endpoint.bookmarks(.collectionItems(bookmarkID: bookmarkID, action: .index)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: newURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "collection_names", value: collectionNames.joined(separator: ", ")),
                URLQueryItem(name: "commit", value: "Add")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "bookmarks")
    }

    func updateUserCollectionItems(
        decisions: [Int: AO3CollectionItemStatus] = [:],
        removeIDs: [Int] = []
    ) async throws {
        guard !decisions.isEmpty || !removeIDs.isEmpty else { return }
        let username = try await resolveCurrentUsername()
        guard let indexURL = AO3Endpoint.user(username: username, route: .collectionItems(.index)).url(),
              let updateURL = AO3Endpoint.user(username: username, route: .collectionItems(.updateMultiple)).url() else {
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
            for (itemID, status) in decisions {
                items.append(URLQueryItem(
                    name: "collection_items[\(itemID)][user_approval_status]",
                    value: status.rawValue
                ))
            }
            for itemID in removeIDs {
                items.append(URLQueryItem(
                    name: "collection_items[\(itemID)][remove]",
                    value: "1"
                ))
            }
            items.append(URLQueryItem(name: "commit", value: "Submit"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "collection_items")
    }
}
