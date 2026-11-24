//
//  SitePOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

internal extension AO3Client {

    func submitAbuseReport(_ draft: AO3AbuseReportDraft) async throws {
        guard let newURL = AO3Endpoint.abuseReport(.new).url(),
              let postURL = AO3Endpoint.abuseReport(.create).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: postURL,
            tokenFallbackURL: newURL
        ) { csrfToken in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "abuse_report[url]", value: draft.reportedURL.absoluteString),
                URLQueryItem(name: "abuse_report[summary]", value: draft.summary),
                URLQueryItem(name: "abuse_report[comment]", value: draft.comment),
                URLQueryItem(name: "abuse_report[email]", value: draft.email),
                URLQueryItem(name: "abuse_report[language]", value: draft.language)
            ]
            if let username = draft.username, !username.isEmpty {
                items.append(URLQueryItem(name: "abuse_report[username]", value: username))
            }
            items.append(URLQueryItem(name: "commit", value: "Submit"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }
    }

    func submitSupportRequest(_ draft: AO3SupportRequestDraft) async throws {
        guard let supportURL = AO3Endpoint.support.url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: supportURL,
            tokenFallbackURL: supportURL
        ) { csrfToken in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "feedback[email]", value: draft.email),
                URLQueryItem(name: "feedback[summary]", value: draft.summary),
                URLQueryItem(name: "feedback[comment]", value: draft.comment),
                URLQueryItem(name: "feedback[category]", value: draft.category),
                URLQueryItem(name: "feedback[language]", value: draft.language)
            ]
            if let username = draft.username, !username.isEmpty {
                items.append(URLQueryItem(name: "feedback[username]", value: username))
            }
            items.append(URLQueryItem(name: "commit", value: "Send"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }
    }
}
