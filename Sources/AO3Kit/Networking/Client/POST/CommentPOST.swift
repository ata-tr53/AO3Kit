//
//  CommentPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 29.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Client {
    /// Posts a new comment or replies to an existing one using the Pseud's display name.
    func postComment(
        content: String,
        pseudName: String,
        chapterID: Int,
        replyToCommentID: Int? = nil
    ) async throws {
        guard let chapterURL = AO3Endpoint.chapter(id: chapterID, route: .main).url() else {
            throw AO3ClientError.invalidURL
        }
        
        let pageHTML = try await performRequest(url: chapterURL, method: .get)
        let csrfToken = try AO3Parser.parseCSRFToken(from: pageHTML)
        
        let pseudMap = try AO3Parser.parsePseudIDs(from: pageHTML)
        print(pseudMap)
        print(pseudName)
        guard let pseudIntID = pseudMap[pseudName] else {
            throw AO3ClientError.pseudNotFound
        }
        
        let commentableType = replyToCommentID != nil ? "Comment" : "Chapter"
        let targetID = replyToCommentID != nil ? String(replyToCommentID!) : String(chapterID)
        
        let parameters: [String: String] = [
            "utf8": "✓",
            "authenticity_token": csrfToken,
            "comment[commentable_type]": commentableType,
            "comment[commentable_id]": targetID,
            "comment[pseud_id]": String(pseudIntID),
            "comment[comment_content]": content,
            "commit": replyToCommentID != nil ? "Reply" : "Comment"
        ]
        
        let postURLString: String
        if let replyID = replyToCommentID {
            postURLString = "https://archiveofourown.org/comments/\(replyID)/comments"
        } else {
            postURLString = "https://archiveofourown.org/chapters/\(chapterID)/comments"
        }
        
        guard let postURL = URL(string: postURLString) else {
            throw AO3ClientError.invalidURL
        }
        
        let headers: [String: String] = [
            "Content-Type": "application/x-www-form-urlencoded",
            "Referer": chapterURL.absoluteString
        ]
        
        let responseHTML = try await performRequest(
            url: postURL,
            method: .post,
            body: parameters.percentEncoded(),
            headers: headers
        )
        
        if responseHTML.contains("errorExplanation") || responseHTML.contains("error") {
            print("⚠️ AO3 returned a silent error in the HTML. Dumping HTML to console:")
            print(responseHTML)
        }

        
        await cache.invalidate(containing: String(chapterID))
    }

}

internal extension Dictionary where Key == String, Value == String {
    func percentEncoded() -> Data? {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~ "))
        
        let parameterArray = self.map { (key, value) -> String in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: allowedCharacters)?.replacingOccurrences(of: " ", with: "+") ?? ""
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: allowedCharacters)?.replacingOccurrences(of: " ", with: "+") ?? ""
            return "\(escapedKey)=\(escapedValue)"
        }
        return parameterArray.joined(separator: "&").data(using: .utf8)
    }
}


internal extension AO3Parser {
    /// Extracts a dictionary mapping Pseud display names to their internal integer IDs from a chapter/work page.
    static func parsePseudIDs(from html: String) throws -> [String: Int] {
        let document = try SwiftSoup.parse(html)
        var pseudMap: [String: Int] = [:]
        
        let options = try document.select("select[name='comment[pseud_id]'] option")
        
        for option in options {
            let name = try option.text()
            if let idString = try? option.attr("value"), let id = Int(idString) {
                pseudMap[name] = id
            }
        }
        
        return pseudMap
    }

}
