//
//  WorksPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

internal extension AO3Client {

    @discardableResult
    func createWork(_ draft: AO3WorkDraft) async throws -> Int? {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let newURL = AO3Endpoint.worksCollection(.new).url(),
              let postURL = AO3Endpoint.worksCollection(.index).url() else {
            throw AO3ClientError.invalidURL
        }

        let formHTML = try await performRequest(url: newURL)
        let context = try AO3Parser.parseWorkFormContext(from: formHTML)
        let pseudIDs = try resolveAuthorPseudIDs(requestedNames: draft.pseudNames, context: context)

        let formItems = buildWorkFormItems(
            draft: draft,
            csrfToken: context.csrfToken,
            pseudIDs: pseudIDs,
            isEditing: false
        )

        let responseHTML = try await performFormPost(url: postURL, formItems: formItems, referer: newURL)
        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "/works")
        return try? AO3Parser.parseWorkIDFromResponse(html: responseHTML)
    }

    func updateWork(id workID: Int, draft: AO3WorkDraft) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let editURL = AO3Endpoint.work(id: workID, route: .edit).url(),
              let updateURL = AO3Endpoint.work(id: workID, route: .main).url() else {
            throw AO3ClientError.invalidURL
        }

        let formHTML = try await performRequest(url: editURL)
        let context = try AO3Parser.parseWorkFormContext(from: formHTML)
        let pseudIDs = try resolveAuthorPseudIDs(requestedNames: draft.pseudNames, context: context)

        let formItems = buildWorkFormItems(
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
    }

    func updateWorkTags(id workID: Int, tags: AO3WorkTagsDraft) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let editTagsURL = AO3Endpoint.work(id: workID, route: .editTags).url(),
              let updateTagsURL = AO3Endpoint.work(id: workID, route: .updateTags).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: updateTagsURL,
            tokenFallbackURL: editTagsURL
        ) { csrfToken in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "work[rating_string]", value: tags.rating.ao3FormString),
                URLQueryItem(name: "work[fandom_string]", value: tags.fandoms.joined(separator: ", ")),
                URLQueryItem(name: "work[relationship_string]", value: tags.relationships.joined(separator: ", ")),
                URLQueryItem(name: "work[character_string]", value: tags.characters.joined(separator: ", ")),
                URLQueryItem(name: "work[freeform_string]", value: tags.additionalTags.joined(separator: ", "))
            ]
            for warning in tags.archiveWarnings {
                if let str = warning.ao3FormString {
                    items.append(URLQueryItem(name: "work[archive_warning_strings][]", value: str))
                }
            }
            for category in tags.categories {
                items.append(URLQueryItem(name: "work[category_strings][]", value: category.ao3FormString))
            }
            if let languageID = tags.languageID {
                items.append(URLQueryItem(name: "work[language_id]", value: String(languageID)))
            }
            items.append(URLQueryItem(name: "update_button", value: "Update"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
    }

    func postWorkDraft(id workID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let workURL = AO3Endpoint.work(id: workID, route: .main).url(),
              let postDraftURL = AO3Endpoint.work(id: workID, route: .postDraft).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postDraftURL,
            tokenFallbackURL: workURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "put"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
        await cache.invalidate(containing: "drafts")
    }

    func deleteWork(id workID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let confirmURL = AO3Endpoint.work(id: workID, route: .confirmDelete).url(),
              let workURL = AO3Endpoint.work(id: workID, route: .main).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: workURL,
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
        await cache.invalidate(containing: "/works")
    }

    @discardableResult
    func importWork(_ draft: AO3WorkImportDraft) async throws -> Int? {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard !draft.urls.isEmpty else { throw AO3ClientError.invalidURL }
        guard let importURL = AO3Endpoint.worksCollection(.import).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: importURL,
            tokenFallbackURL: importURL
        ) { csrfToken in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "urls", value: draft.urls.map(\.absoluteString).joined(separator: "\n")),
                URLQueryItem(name: "import_multiple", value: draft.importAsChapters ? "chapters" : "works"),
                URLQueryItem(name: "override_tags", value: draft.overrideTags ? "1" : "0"),
                URLQueryItem(name: "post_without_preview", value: draft.postWithoutPreview ? "1" : "0"),
                URLQueryItem(name: "restricted", value: draft.isRestricted ? "1" : "0")
            ]
            if !draft.fandoms.isEmpty {
                items.append(URLQueryItem(name: "work[fandom_string]", value: draft.fandoms.joined(separator: ", ")))
            }
            if let rating = draft.rating {
                items.append(URLQueryItem(name: "work[rating_string]", value: rating.ao3FormString))
            }
            for warning in draft.archiveWarnings {
                if let str = warning.ao3FormString {
                    items.append(URLQueryItem(name: "work[archive_warning_strings][]", value: str))
                }
            }
            if let languageID = draft.languageID {
                items.append(URLQueryItem(name: "work[language_id]", value: String(languageID)))
            }
            items.append(URLQueryItem(name: "commit", value: "Import"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "/works")
        return try? AO3Parser.parseWorkIDFromResponse(html: responseHTML)
    }

    func orphanWork(id workID: Int, useDefaultPseud: Bool = true) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let newOrphanURL = AO3Endpoint.orphan(.new).url(),
              let postOrphanURL = AO3Endpoint.orphan(.index).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postOrphanURL,
            tokenFallbackURL: newOrphanURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "work_id", value: String(workID)),
                URLQueryItem(name: "use_default", value: useDefaultPseud ? "true" : "false"),
                URLQueryItem(name: "commit", value: "Yes, I'm sure")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
    }

    func removeWorkCreatorship(workID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let workURL = AO3Endpoint.work(id: workID, route: .main).url(),
              let removeURL = AO3Endpoint.work(id: workID, route: .removeUserCreatorship).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: removeURL,
            tokenFallbackURL: workURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(workID))
    }

    // MARK: - Helpers

    internal func resolveAuthorPseudIDs(
        requestedNames: [String],
        context: AO3Parser.AO3WorkFormContext
    ) throws -> [Int] {
        if requestedNames.isEmpty {
            return context.defaultPseudID.map { [$0] } ?? []
        }
        var ids: [Int] = []
        for name in requestedNames {
            guard let id = context.pseudMap[name] else {
                throw AO3ClientError.pseudNotFound
            }
            ids.append(id)
        }
        return ids
    }

    private func buildWorkFormItems(
        draft: AO3WorkDraft,
        csrfToken: String,
        pseudIDs: [Int],
        isEditing: Bool
    ) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "utf8", value: "✓"),
            URLQueryItem(name: "authenticity_token", value: csrfToken),
            URLQueryItem(name: "work[rating_string]", value: draft.rating.ao3FormString),
            URLQueryItem(name: "work[fandom_string]", value: draft.fandoms.joined(separator: ", ")),
            URLQueryItem(name: "work[relationship_string]", value: draft.relationships.joined(separator: ", ")),
            URLQueryItem(name: "work[character_string]", value: draft.characters.joined(separator: ", ")),
            URLQueryItem(name: "work[freeform_string]", value: draft.additionalTags.joined(separator: ", ")),
            URLQueryItem(name: "work[title]", value: draft.title),
            URLQueryItem(name: "work[summary]", value: draft.summary),
            URLQueryItem(name: "work[notes]", value: draft.notes),
            URLQueryItem(name: "work[endnotes]", value: draft.endNotes),
            URLQueryItem(name: "work[collection_names]", value: draft.collections.joined(separator: ", ")),
            URLQueryItem(name: "work[recipients]", value: draft.recipients.joined(separator: ", ")),
            URLQueryItem(name: "work[language_id]", value: String(draft.languageID)),
            URLQueryItem(name: "work[restricted]", value: draft.isRestricted ? "1" : "0"),
            URLQueryItem(name: "work[moderated_commenting_enabled]", value: draft.isModeratedComments ? "1" : "0"),
            URLQueryItem(name: "work[comment_permissions]", value: draft.commentPermissions.rawValue),
            URLQueryItem(name: "work[chapter_attributes][content]", value: draft.chapterContent)
        ]

        if isEditing {
            items.insert(URLQueryItem(name: "_method", value: "patch"), at: 1)
        }

        for warning in draft.archiveWarnings {
            if let str = warning.ao3FormString {
                items.append(URLQueryItem(name: "work[archive_warning_strings][]", value: str))
            }
        }
        for category in draft.categories {
            items.append(URLQueryItem(name: "work[category_strings][]", value: category.ao3FormString))
        }
        for pseudID in pseudIDs {
            items.append(URLQueryItem(name: "work[author_attributes][ids][]", value: String(pseudID)))
        }
        if let workSkinID = draft.workSkinID {
            items.append(URLQueryItem(name: "work[work_skin_id]", value: String(workSkinID)))
        }
        if draft.isMultiChapter {
            items.append(URLQueryItem(name: "chapters-options-show", value: "1"))
            items.append(URLQueryItem(name: "work[wip_length]", value: draft.expectedChapters.map(String.init) ?? "?"))
            if let chapterTitle = draft.chapterTitle {
                items.append(URLQueryItem(name: "work[chapter_attributes][title]", value: chapterTitle))
            }
        }

        if isEditing {
            items.append(URLQueryItem(name: "update_button", value: "Update"))
        } else if draft.saveAsDraft {
            items.append(URLQueryItem(name: "save_button", value: "Save As Draft"))
        } else {
            items.append(URLQueryItem(name: "post_button", value: "Post"))
        }

        return items
    }
}
