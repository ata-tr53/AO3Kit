//
//  ChaptersPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

internal extension AO3Client {

    func createChapter(workID: Int, draft: AO3ChapterDraft) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let newURL = AO3Endpoint.work(id: workID, route: .chapters(.new)).url(),
              let postURL = AO3Endpoint.work(id: workID, route: .chapters(.index)).url() else {
            throw AO3ClientError.invalidURL
        }

        let formHTML = try await performRequest(url: newURL)
        let context = try AO3Parser.parseWorkFormContext(from: formHTML)
        let pseudIDs = try resolveAuthorPseudIDs(requestedNames: draft.pseudNames, context: context)

        let formItems = buildChapterFormItems(
            draft: draft,
            csrfToken: context.csrfToken,
            pseudIDs: pseudIDs,
            isEditing: false
        )

        let responseHTML = try await performFormPost(url: postURL, formItems: formItems, referer: newURL)
        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
    }

    func updateChapter(workID: Int, chapterID: Int, draft: AO3ChapterDraft) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let editURL = AO3Endpoint.work(id: workID, route: .chapters(.edit(id: chapterID))).url(),
              let updateURL = AO3Endpoint.work(id: workID, route: .chapters(.show(id: chapterID))).url() else {
            throw AO3ClientError.invalidURL
        }

        let formHTML = try await performRequest(url: editURL)
        let context = try AO3Parser.parseWorkFormContext(from: formHTML)
        let pseudIDs = try resolveAuthorPseudIDs(requestedNames: draft.pseudNames, context: context)

        let formItems = buildChapterFormItems(
            draft: draft,
            csrfToken: context.csrfToken,
            pseudIDs: pseudIDs,
            isEditing: true
        )

        let responseHTML = try await performFormPost(url: updateURL, formItems: formItems, referer: editURL)
        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
        await cache.invalidate(containing: String(chapterID))
    }

    func postChapterDraft(workID: Int, chapterID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let chapterURL = AO3Endpoint.work(id: workID, route: .chapters(.show(id: chapterID))).url(),
              let postURL = AO3Endpoint.work(id: workID, route: .chapters(.post(id: chapterID))).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: chapterURL
        ) { csrfToken in
            [
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "post_button", value: "Post")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
        await cache.invalidate(containing: String(chapterID))
    }

    func deleteChapter(workID: Int, chapterID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let confirmURL = AO3Endpoint.work(id: workID, route: .chapters(.confirmDelete(id: chapterID))).url(),
              let chapterURL = AO3Endpoint.work(id: workID, route: .chapters(.show(id: chapterID))).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: chapterURL,
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

        await cache.invalidate(containing: String(workID))
        await cache.invalidate(containing: String(chapterID))
    }

    func reorderChapters(workID: Int, chapterIDsInOrder: [Int]) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard !chapterIDsInOrder.isEmpty else { return }
        guard let manageURL = AO3Endpoint.work(id: workID, route: .chapters(.manage)).url(),
              let updatePositionsURL = AO3Endpoint.work(id: workID, route: .chapters(.updatePositions)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: updatePositionsURL,
            tokenFallbackURL: manageURL
        ) { csrfToken in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
            for id in chapterIDsInOrder {
                items.append(URLQueryItem(name: "chapters[]", value: String(id)))
            }
            items.append(URLQueryItem(name: "commit", value: "Update Positions"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
    }

    // MARK: - Helpers

    private func buildChapterFormItems(
        draft: AO3ChapterDraft,
        csrfToken: String,
        pseudIDs: [Int],
        isEditing: Bool
    ) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "utf8", value: "✓"),
            URLQueryItem(name: "authenticity_token", value: csrfToken),
            URLQueryItem(name: "chapter[title]", value: draft.title),
            URLQueryItem(name: "chapter[summary]", value: draft.summary),
            URLQueryItem(name: "chapter[notes]", value: draft.notes),
            URLQueryItem(name: "chapter[endnotes]", value: draft.endNotes),
            URLQueryItem(name: "chapter[content]", value: draft.content)
        ]

        if isEditing {
            items.insert(URLQueryItem(name: "_method", value: "patch"), at: 1)
        }

        if let position = draft.position {
            items.append(URLQueryItem(name: "chapter[position]", value: String(position)))
        }
        if let wipLength = draft.wipLength {
            items.append(URLQueryItem(name: "chapter[wip_length]", value: wipLength))
        }
        if let publishedAt = draft.publishedAt {
            let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: publishedAt)
            if let year = comps.year, let month = comps.month, let day = comps.day {
                items.append(URLQueryItem(name: "chapter[published_at(1i)]", value: String(year)))
                items.append(URLQueryItem(name: "chapter[published_at(2i)]", value: String(month)))
                items.append(URLQueryItem(name: "chapter[published_at(3i)]", value: String(day)))
            }
        }
        for pseudID in pseudIDs {
            items.append(URLQueryItem(name: "chapter[author_attributes][ids][]", value: String(pseudID)))
        }

        if isEditing {
            items.append(URLQueryItem(name: "post_button", value: "Update"))
        } else if draft.saveAsDraft {
            items.append(URLQueryItem(name: "save_button", value: "Save As Draft"))
        } else {
            items.append(URLQueryItem(name: "post_button", value: "Post"))
        }

        return items
    }
}
