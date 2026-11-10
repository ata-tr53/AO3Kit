//
//  CommentPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 29.09.2026.
//

import Foundation
import SwiftSoup

internal extension AO3Client {
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
        
        let postURLString: String
        if let replyID = replyToCommentID {
            postURLString = "https://archiveofourown.org/comments/\(replyID)/comments"
        } else {
            postURLString = "https://archiveofourown.org/chapters/\(chapterID)/comments"
        }
        
        guard let postURL = URL(string: postURLString) else {
            throw AO3ClientError.invalidURL
        }
        
        let responseHTML = try await performFormPost(
            url: postURL,
            formItems: [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "comment[commentable_type]", value: commentableType),
                URLQueryItem(name: "comment[commentable_id]", value: targetID),
                URLQueryItem(name: "comment[pseud_id]", value: String(pseudIntID)),
                URLQueryItem(name: "comment[comment_content]", value: content),
                URLQueryItem(name: "commit", value: replyToCommentID != nil ? "Reply" : "Comment")
            ],
            referer: chapterURL
        )
        
        if responseHTML.contains("errorExplanation") || responseHTML.contains("error") {
            print("⚠️ AO3 returned a silent error in the HTML. Dumping HTML to console:")
            print(responseHTML)
        }

        await cache.invalidate(containing: String(chapterID))
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
