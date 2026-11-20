//
//  BookmarksPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

internal extension AO3Client {

    // MARK: - Single Bookmark Fetch

    func fetchBookmark(
        id: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3FicBookmark {
        try await fetchCachedItem(
            endpoint: .bookmarks(.show(id: id)),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseSingleBookmark(html: html)
        }
    }

    // MARK: - Create / Update / Delete Bookmarks

    func createBookmark(for target: AO3BookmarkTarget, draft: AO3BookmarkDraft) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let formURL = target.newFormEndpoint.url(bypassAdultBlock: self.bypassAdultBlock) else {
            throw AO3ClientError.invalidURL
        }

        let formHTML = try await performRequest(url: formURL, method: .get)
        let context = try AO3Parser.parseBookmarkFormContext(from: formHTML)

        try await submitBookmarkForm(context: context, draft: draft, referer: formURL)

        await cache.invalidate(containing: "bookmarks")
        await cache.invalidate(containing: target.cacheIdentifier)
    }

    func updateBookmark(id: Int, draft: AO3BookmarkDraft) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let editURL = AO3Endpoint.bookmarks(.edit(id: id)).url() else {
            throw AO3ClientError.invalidURL
        }

        let formHTML = try await performRequest(url: editURL, method: .get)
        let context = try AO3Parser.parseBookmarkFormContext(from: formHTML)

        try await submitBookmarkForm(context: context, draft: draft, referer: editURL)

        await cache.invalidate(containing: "bookmarks")
        await cache.invalidate(containing: String(id))
    }

    func deleteBookmark(id: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let bookmarkURL = AO3Endpoint.bookmarks(.show(id: id)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: bookmarkURL,
            tokenFallbackURL: bookmarkURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "bookmarks")
        await cache.invalidate(containing: String(id))
    }

    // MARK: - Shared Form Submission

    private func submitBookmarkForm(
        context: AO3Parser.AO3BookmarkFormContext,
        draft: AO3BookmarkDraft,
        referer: URL
    ) async throws {
        let pseudID: Int
        if let requestedPseud = draft.pseudName {
            guard let matchedID = context.pseudMap[requestedPseud] else {
                throw AO3ClientError.pseudNotFound
            }
            pseudID = matchedID
        } else {
            pseudID = context.defaultPseudID
        }

        let actionURLString = context.actionPath.hasPrefix("http")
            ? context.actionPath
            : "https://archiveofourown.org\(context.actionPath)"
        guard let postURL = URL(string: actionURLString) else {
            throw AO3ClientError.invalidURL
        }

        var formItems: [URLQueryItem] = [
            URLQueryItem(name: "utf8", value: "✓"),
            URLQueryItem(name: "authenticity_token", value: context.csrfToken),
            URLQueryItem(name: "bookmark[pseud_id]", value: String(pseudID)),
            URLQueryItem(name: "bookmark[bookmarker_notes]", value: draft.notes),
            URLQueryItem(name: "bookmark[tag_string]", value: draft.tags.joined(separator: ", ")),
            URLQueryItem(name: "bookmark[collection_names]", value: draft.collections.joined(separator: ", ")),
            URLQueryItem(name: "bookmark[private]", value: draft.isPrivate ? "1" : "0"),
            URLQueryItem(name: "bookmark[rec]", value: draft.isRec ? "1" : "0"),
            URLQueryItem(name: "commit", value: context.isEditing ? "Update" : "Create")
        ]

        if context.isEditing {
            formItems.insert(URLQueryItem(name: "_method", value: "patch"), at: 1)
        }

        let responseHTML = try await performFormPost(
            url: postURL,
            formItems: formItems,
            referer: referer
        )

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }
    }
}
