//
//  CommentPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 29.09.2026.
//

import Foundation
import SwiftSoup
import OSLog

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
        
        Logger.network.log("Pseuds: \n \(pseudMap) \n\n \(pseudName)")
        
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
        
        if responseHTML.contains("errorExplanation") {
            Logger.network.error("⚠️ AO3 returned a silent error in the HTML. Dumping HTML to console: \n \(responseHTML)")
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(chapterID))
    }

    /// Posts a comment or reply on any `AO3Commentable` (work, chapter, admin post, or comment thread).
    func postComment<Target: AO3Commentable>(
        on target: Target,
        content: String,
        pseudName: String
    ) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let hostURL = target.commentHostEndpoint.url(bypassAdultBlock: self.bypassAdultBlock),
              let postURL = target.postCommentEndpoint.url() else {
            throw AO3ClientError.invalidURL
        }

        let pageHTML = try await performRequest(url: hostURL, method: .get)
        let csrfToken = try AO3Parser.parseCSRFToken(from: pageHTML)
        let pseudMap = try AO3Parser.parsePseudIDs(from: pageHTML)

        guard let pseudIntID = pseudMap[pseudName] else {
            throw AO3ClientError.pseudNotFound
        }

        let isReply = target.commentableType == .comment
        let responseHTML = try await performFormPost(
            url: postURL,
            formItems: [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "comment[commentable_type]", value: target.commentableType.rawValue),
                URLQueryItem(name: "comment[commentable_id]", value: String(target.commentableID)),
                URLQueryItem(name: "comment[pseud_id]", value: String(pseudIntID)),
                URLQueryItem(name: "comment[comment_content]", value: content),
                URLQueryItem(name: "commit", value: isReply ? "Reply" : "Comment")
            ],
            referer: hostURL
        )

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(target.commentableID))
        await cache.invalidate(containing: "comments")
    }

    /// Edits the body of an existing comment (`PATCH /comments/:id`).
    func editComment(id commentID: Int, content: String) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let editURL = AO3Endpoint.comments(.edit(id: commentID)).url(),
              let postURL = AO3Endpoint.commentThread(id: commentID).url() else {
            throw AO3ClientError.invalidURL
        }

        let editHTML = try await performRequest(url: editURL, method: .get)
        let csrfToken = try AO3Parser.parseCSRFToken(from: editHTML)

        let responseHTML = try await performFormPost(
            url: postURL,
            formItems: [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "_method", value: "patch"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "comment[comment_content]", value: content),
                URLQueryItem(name: "commit", value: "Update")
            ],
            referer: editURL
        )

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(commentID))
        await cache.invalidate(containing: "comments")
    }

    /// Deletes an existing comment (`DELETE /comments/:id`).
    func deleteComment(id commentID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let commentURL = AO3Endpoint.commentThread(id: commentID).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: commentURL,
            tokenFallbackURL: commentURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(commentID))
        await cache.invalidate(containing: "comments")
    }

    /// Performs a moderation action (approve, reject, review, freeze, unfreeze, hide, unhide) on a comment (`PUT /comments/:id/:action`).
    func moderateComment(id commentID: Int, action: AO3CommentModerationAction) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let commentURL = AO3Endpoint.commentThread(id: commentID).url(),
              let actionURL = action.endpoint(for: commentID).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: actionURL,
            tokenFallbackURL: commentURL
        ) { csrfToken in
            [
                URLQueryItem(name: "_method", value: "put"),
                URLQueryItem(name: "authenticity_token", value: csrfToken)
            ]
        }

        if responseHTML.contains("errorExplanation") {
            throw AO3ClientError.invalidData
        }

        await cache.invalidate(containing: String(commentID))
        await cache.invalidate(containing: "comments")
    }

    /// Approves all unreviewed moderated comments on a work (`PUT /works/:id/comments/review_all`).
    func reviewAllComments(forWorkID workID: Int) async throws {
        guard isLoggedIn else { throw AO3ClientError.requiresRegistration }
        guard let unreviewedURL = AO3Endpoint.work(id: workID, route: .comments(.unreviewed)).url(),
              let reviewAllURL = AO3Endpoint.work(id: workID, route: .comments(.reviewAll)).url() else {
            throw AO3ClientError.invalidURL
        }

        let responseHTML = try await performAuthenticatedFormPost(
            url: reviewAllURL,
            tokenFallbackURL: unreviewedURL
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
        await cache.invalidate(containing: "comments")
    }
}
