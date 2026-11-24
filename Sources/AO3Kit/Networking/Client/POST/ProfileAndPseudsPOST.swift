//
//  ProfileAndPseudsPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

internal extension AO3Client {

    // MARK: - Profile

    func fetchProfileDraft() async throws -> AO3ProfileDraft {
        let username = try await resolveCurrentUsername()
        guard let editURL = AO3Endpoint.user(username: username, route: .editProfile).url() else {
            throw AO3ClientError.invalidURL
        }
        let html = try await performRequest(url: editURL)
        return try AO3Parser.parseProfileDraft(from: html)
    }

    func updateProfile(_ draft: AO3ProfileDraft) async throws {
        let username = try await resolveCurrentUsername()
        guard let editURL = AO3Endpoint.user(username: username, route: .editProfile).url(),
              let updateURL = AO3Endpoint.user(username: username, route: .profile).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: updateURL,
            tokenFallbackURL: editURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "profile_attributes[title]", value: draft.title),
                URLQueryItem(name: "profile_attributes[about_me]", value: draft.aboutMe),
                URLQueryItem(name: "commit", value: "Update")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "/users/\(username)/profile")
    }

    // MARK: - Pseuds

    func createPseud(_ draft: AO3PseudDraft) async throws {
        let username = try await resolveCurrentUsername()
        guard let newURL = AO3Endpoint.user(username: username, route: .newPseud).url(),
              let createURL = AO3Endpoint.user(username: username, route: .allPseuds).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: createURL,
            tokenFallbackURL: newURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "pseud[name]", value: draft.name),
                URLQueryItem(name: "pseud[description]", value: draft.description),
                URLQueryItem(name: "pseud[is_default]", value: draft.isDefault ? "1" : "0"),
                URLQueryItem(name: "pseud[icon_alt_text]", value: draft.iconAltText),
                URLQueryItem(name: "pseud[icon_comment_text]", value: draft.iconCommentText),
                URLQueryItem(name: "commit", value: "Create")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "/users/\(username)/pseuds")
        await cache.invalidate(containing: "/users/\(username)/profile")
    }

    func updatePseud(named currentName: String, draft: AO3PseudDraft) async throws {
        let username = try await resolveCurrentUsername()
        guard let editURL = AO3Endpoint.user(username: username, route: .editPseud(name: currentName)).url(),
              let updateURL = AO3Endpoint.user(username: username, route: .pseud(name: currentName)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: updateURL,
            tokenFallbackURL: editURL
        ) { csrfToken in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "pseud[name]", value: draft.name),
                URLQueryItem(name: "pseud[description]", value: draft.description),
                URLQueryItem(name: "pseud[is_default]", value: draft.isDefault ? "1" : "0"),
                URLQueryItem(name: "pseud[icon_alt_text]", value: draft.iconAltText),
                URLQueryItem(name: "pseud[icon_comment_text]", value: draft.iconCommentText)
            ]
            if draft.deleteIcon {
                items.append(URLQueryItem(name: "pseud[delete_icon]", value: "1"))
            }
            items.append(URLQueryItem(name: "commit", value: "Update"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "/users/\(username)/pseuds")
        await cache.invalidate(containing: "/users/\(username)/profile")
    }

    func deletePseud(named name: String) async throws {
        let username = try await resolveCurrentUsername()
        guard let listURL = AO3Endpoint.user(username: username, route: .allPseuds).url(),
              let pseudURL = AO3Endpoint.user(username: username, route: .pseud(name: name)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: pseudURL,
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

        await cache.invalidate(containing: "/users/\(username)/pseuds")
        await cache.invalidate(containing: "/users/\(username)/profile")
    }
}
