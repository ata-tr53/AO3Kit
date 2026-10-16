//
//  KudosPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

public extension AO3Client {
    
    /// Leaves a kudo on a specific work.
    /// - Parameter workID: The ID of the work to kudo.
    /// - Returns: A boolean indicating success. Throws an error if it fails.
    @discardableResult
    func leaveKudos(for workID: Int) async throws -> Bool {
        guard let workURL = AO3Endpoint.work(id: workID, route: .main).url(bypassAdultBlock: bypassAdultBlock) else {
            throw AO3ClientError.invalidURL
        }
        
        let workHTML = try await performRequest(url: workURL, method: .get)
        let csrfToken = try AO3Parser.parseCSRFToken(from: workHTML)
        
        let parameters = [
            "utf8": "✓",
            "authenticity_token": csrfToken,
            "kudo[commentable_id]": String(workID),
            "kudo[commentable_type]": "Work"
        ]
        
        let postString = parameters.map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            return "\(escapedKey)=\(escapedValue)"
        }.joined(separator: "&")
        
        guard let postData = postString.data(using: .utf8) else {
            throw AO3ClientError.invalidData
        }
        
        guard let kudosURL = URL(string: "https://archiveofourown.org/kudos") else {
            throw AO3ClientError.invalidURL
        }
        
        let customHeaders = [
            "X-Requested-With": "XMLHttpRequest",
            "X-CSRF-Token": csrfToken,
            "Accept": "*/*;q=0.5, text/javascript, application/javascript",
            "Origin": "https://archiveofourown.org",
            "Referer": workURL.absoluteString
        ]
        
        let responseHTML = try await performRequest(url: kudosURL, method: .post, body: postData, headers: customHeaders)
        
        return true
    }

    
}
