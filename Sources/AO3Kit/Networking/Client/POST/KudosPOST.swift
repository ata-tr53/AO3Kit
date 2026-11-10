//
//  KudosPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

internal extension AO3Client {
    
    /// Leaves a kudo on a specific work.
    /// - Parameter workID: The ID of the work to kudo.
    /// - Returns: A boolean indicating success. Throws an error if it fails.
    @discardableResult
    func leaveKudos(for workID: Int) async throws -> Bool {
        guard let workURL = AO3Endpoint.work(id: workID, route: .main).url(bypassAdultBlock: bypassAdultBlock),
              let kudosURL = URL(string: "https://archiveofourown.org/kudos") else {
            throw AO3ClientError.invalidURL
        }
        
        _ = try await performAuthenticatedFormPost(
            url: kudosURL,
            tokenFallbackURL: workURL,
            includeXHRHeaders: true,
            additionalHeaders: [
                "Accept": "*/*;q=0.5, text/javascript, application/javascript"
            ]
        ) { csrfToken in
            [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "kudo[commentable_id]", value: String(workID)),
                URLQueryItem(name: "kudo[commentable_type]", value: "Work")
            ]
        }
        
        return true
    }

    
}
