//
//  SeriesPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

internal extension AO3Client {

    func updateSeries(id seriesID: Int, draft: AO3SeriesDraft) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let editURL = AO3Endpoint.series(id: seriesID, route: .edit).url(),
              let updateURL = AO3Endpoint.series(id: seriesID, route: .main).url() else {
            throw AO3ClientError.invalidURL
        }

        let formHTML = try await performRequest(url: editURL)
        let csrfToken = try AO3Parser.parseCSRFToken(from: formHTML)
        let context = try? AO3Parser.parseWorkFormContext(from: formHTML)

        var items: [URLQueryItem] = [
            URLQueryItem(name: "utf8", value: "✓"),
            URLQueryItem(name: "_method", value: "patch"),
            URLQueryItem(name: "authenticity_token", value: csrfToken),
            URLQueryItem(name: "series[title]", value: draft.title),
            URLQueryItem(name: "series[summary]", value: draft.summary),
            URLQueryItem(name: "series[series_notes]", value: draft.notes),
            URLQueryItem(name: "series[complete]", value: draft.isComplete ? "1" : "0")
        ]

        if let context {
            let pseudIDs = try resolveAuthorPseudIDs(requestedNames: draft.pseudNames, context: context)
            for id in pseudIDs {
                items.append(URLQueryItem(name: "series[author_attributes][ids][]", value: String(id)))
            }
        }

        items.append(URLQueryItem(name: "commit", value: "Update"))

        let responseHTML = try await performFormPost(url: updateURL, formItems: items, referer: editURL)
        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "/series/\(seriesID)")
    }

    func deleteSeries(id seriesID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let confirmURL = AO3Endpoint.series(id: seriesID, route: .confirmDelete).url(),
              let seriesURL = AO3Endpoint.series(id: seriesID, route: .main).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: seriesURL,
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

        await cache.invalidate(containing: "/series/\(seriesID)")
        await cache.invalidate(containing: "/series")
    }

    func reorderSeriesWorks(seriesID: Int, serialWorkIDsInOrder: [Int]) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard !serialWorkIDsInOrder.isEmpty else { return }
        guard let manageURL = AO3Endpoint.series(id: seriesID, route: .manage).url(),
              let updatePositionsURL = AO3Endpoint.series(id: seriesID, route: .updatePositions).url() else {
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
            for id in serialWorkIDsInOrder {
                items.append(URLQueryItem(name: "serial_works[]", value: String(id)))
            }
            items.append(URLQueryItem(name: "commit", value: "Update Positions"))
            return items
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "/series/\(seriesID)")
    }

    func removeSeriesCreatorship(seriesID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let seriesURL = AO3Endpoint.series(id: seriesID, route: .main).url(),
              let removeURL = AO3Endpoint.series(id: seriesID, route: .removeUserCreatorship).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: removeURL,
            tokenFallbackURL: seriesURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: "/series/\(seriesID)")
    }
}
