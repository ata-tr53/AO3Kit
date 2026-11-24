//
//  CredentialsAndInvitesPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

internal extension AO3Client {

    // MARK: - Password Reset & Account Credentials

    func requestPasswordReset(loginOrEmail: String) async throws {
        guard let newURL = AO3Endpoint.usersCollection(.password(.new)).url(),
              let postURL = AO3Endpoint.usersCollection(.password(.root)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: newURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "user[login]", value: loginOrEmail),
                URLQueryItem(name: "commit", value: "Reset Password")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        let username = try await resolveCurrentUsername()
        guard let formURL = AO3Endpoint.user(username: username, route: .changePassword).url(),
              let postURL = AO3Endpoint.user(username: username, route: .changedPassword).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: formURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "password_check", value: currentPassword),
                URLQueryItem(name: "password", value: newPassword),
                URLQueryItem(name: "password_confirmation", value: newPassword),
                URLQueryItem(name: "commit", value: "Change Password")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }
    }

    func changeEmail(currentPassword: String, newEmail: String) async throws {
        let username = try await resolveCurrentUsername()
        guard let formURL = AO3Endpoint.user(username: username, route: .changeEmail).url(),
              let postURL = AO3Endpoint.user(username: username, route: .changedEmail).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: formURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "password_check", value: currentPassword),
                URLQueryItem(name: "new_email", value: newEmail),
                URLQueryItem(name: "email_confirmation", value: newEmail),
                URLQueryItem(name: "commit", value: "Change Email")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }
    }

    func changeUsername(currentPassword: String, newUsername: String) async throws {
        let username = try await resolveCurrentUsername()
        guard let formURL = AO3Endpoint.user(username: username, route: .changeUsername).url(),
              let postURL = AO3Endpoint.user(username: username, route: .changedUsername).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: formURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "password", value: currentPassword),
                URLQueryItem(name: "new_login", value: newUsername),
                URLQueryItem(name: "commit", value: "Change User Name")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        self.cachedUsername = newUsername
        await cache.invalidate(containing: "/users/\(username)")
    }

    func reconfirmEmail() async throws {
        let username = try await resolveCurrentUsername()
        guard let url = AO3Endpoint.user(username: username, route: .reconfirmEmail).url() else {
            throw AO3ClientError.invalidURL
        }
        _ = try await performRequest(url: url)
    }

    // MARK: - Invite Queue & User Invitations

    func requestInvitation(email: String) async throws {
        guard let queueURL = AO3Endpoint.inviteRequest(.index).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: queueURL,
            tokenFallbackURL: queueURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "invite_request[email]", value: email),
                URLQueryItem(name: "commit", value: "Add me to the list")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }
    }

    func fetchInviteQueueStatus(email: String) async throws -> AO3InviteQueueStatus {
        guard let baseURL = AO3Endpoint.inviteRequest(.showAction).url(),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw AO3ClientError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        guard let url = components.url else { throw AO3ClientError.invalidURL }

        let html = try await performRequest(url: url)
        return try AO3Parser.parseInviteQueueStatus(html: html, email: email)
    }

    func fetchUserInvitations(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Invitation] {
        let username = try await resolveCurrentUsername()
        return try await fetchCachedItem(
            endpoint: .user(username: username, route: .invitations(.index)),
            cacheKey: "user_invitations_\(username)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseUserInvitations(html: html)
        }
    }

    func inviteFriend(email: String) async throws {
        let username = try await resolveCurrentUsername()
        guard let listURL = AO3Endpoint.user(username: username, route: .invitations(.index)).url(),
              let postURL = AO3Endpoint.user(username: username, route: .invitations(.inviteFriend)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: listURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "invitation[invitee_email]", value: email),
                URLQueryItem(name: "commit", value: "Send")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "user_invitations_\(username)")
    }

    func requestUserInvitations(quantity: Int, reason: String) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let newURL = AO3Endpoint.userInviteRequest(.new).url(),
              let postURL = AO3Endpoint.userInviteRequest(.index).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: newURL
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "user_invite_request[quantity]", value: String(quantity)),
                URLQueryItem(name: "user_invite_request[reason]", value: reason),
                URLQueryItem(name: "commit", value: "Send Request")
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }
    }
}
