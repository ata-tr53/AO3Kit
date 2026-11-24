//
//  ExternalWorksPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

internal extension AO3Client {

    func fetchExternalWork(
        id: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3ExternalWork {
        try await fetchCachedItem(
            endpoint: .externalWork(.show(id: id)),
            cacheKey: "external_work_\(id)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseExternalWork(html: html, id: id)
        }
    }

    /// Creates an external work along with its initial bookmark (`POST /bookmarks` via `/external_works/new`).
    func createExternalWorkBookmark(
        externalWork: AO3ExternalWorkDraft,
        bookmark: AO3BookmarkDraft = AO3BookmarkDraft()
    ) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let newURL = AO3Endpoint.externalWork(.new).url(),
              let postURL = AO3Endpoint.bookmarks(.index).url() else {
            throw AO3ClientError.invalidURL
        }

        let formHTML = try await performRequest(url: newURL)
        let context = try AO3Parser.parseBookmarkFormContext(from: formHTML)

        let pseudID: Int
        if let requestedPseud = bookmark.pseudName {
            guard let matched = context.pseudMap[requestedPseud] else {
                throw AO3ClientError.pseudNotFound
            }
            pseudID = matched
        } else {
            pseudID = context.defaultPseudID
        }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "utf8", value: "✓"),
            URLQueryItem(name: "authenticity_token", value: context.csrfToken),
            URLQueryItem(name: "external_work[url]", value: externalWork.url.absoluteString),
            URLQueryItem(name: "external_work[author]", value: externalWork.author),
            URLQueryItem(name: "external_work[title]", value: externalWork.title),
            URLQueryItem(name: "external_work[summary]", value: externalWork.summary),
            URLQueryItem(name: "external_work[fandom_string]", value: externalWork.fandoms.joined(separator: ", ")),
            URLQueryItem(name: "external_work[rating_string]", value: externalWork.rating.ao3FormString),
            URLQueryItem(name: "external_work[relationship_string]", value: externalWork.relationships.joined(separator: ", ")),
            URLQueryItem(name: "external_work[character_string]", value: externalWork.characters.joined(separator: ", ")),
            URLQueryItem(name: "external_work[freeform_string]", value: externalWork.additionalTags.joined(separator: ", ")),
            URLQueryItem(name: "bookmark[pseud_id]", value: String(pseudID)),
            URLQueryItem(name: "bookmark[bookmarker_notes]", value: bookmark.notes),
            URLQueryItem(name: "bookmark[tag_string]", value: bookmark.tags.joined(separator: ", ")),
            URLQueryItem(name: "bookmark[collection_names]", value: bookmark.collections.joined(separator: ", ")),
            URLQueryItem(name: "bookmark[private]", value: bookmark.isPrivate ? "1" : "0"),
            URLQueryItem(name: "bookmark[rec]", value: bookmark.isRec ? "1" : "0"),
            URLQueryItem(name: "commit", value: "Create")
        ]

        for category in externalWork.categories {
            items.append(URLQueryItem(name: "external_work[category_strings][]", value: category.ao3FormString))
        }

        let responseHTML = try await performFormPost(url: postURL, formItems: items, referer: newURL)
        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "bookmarks")
    }
}
