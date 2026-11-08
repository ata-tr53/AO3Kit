//
//  AuthPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

public extension AO3Client {
    
    /// Authenticates the client with AO3.
    /// - Returns: `true` if login succeeds. Throws an error if credentials fail or the network drops.
    @discardableResult
    func login(username: String, password: String, rememberMe: Bool = true) async throws -> Bool {
        guard let loginURL = URL(string: "https://archiveofourown.org/users/login") else {
            throw AO3ClientError.invalidURL
        }
        
        let loginPageHTML = try await performRequest(url: loginURL, method: .get)
        let csrfToken = try AO3Parser.parseCSRFToken(from: loginPageHTML)
        
        let responseHTML = try await performFormPost(
            url: loginURL,
            formItems: [
                URLQueryItem(name: "utf8", value: "✓"),
                URLQueryItem(name: "authenticity_token", value: csrfToken),
                URLQueryItem(name: "user[login]", value: username),
                URLQueryItem(name: "user[password]", value: password),
                URLQueryItem(name: "user[remember_me]", value: "\(rememberMe ? 1 : 0)"),
                URLQueryItem(name: "commit", value: "Log In")
            ],
            referer: loginURL
        )
        
        if responseHTML.contains("Successfully logged in") || responseHTML.contains("Hi, \(username)!") {
            return true
        } else if responseHTML.contains("Invalid user name or password") {
            throw AO3ClientError.invalidCredentials
        } else {
            throw AO3ClientError.invalidData
        }
    }
    
    // MARK: History & Marked for Later
    
    func toggleMarkForLater(workID: Int, isMarkingForLater: Bool) async throws {
        
        guard let getUrl = AO3Endpoint.work(id: workID, route: .main).url() else { throw AO3ClientError.invalidURL }
        let html = try await self.performRequest(url: getUrl, method: .get)
        let token = try AO3Parser.parseCSRFToken(from: html)
        
        let route: AO3WorkRoute = isMarkingForLater ? .markForLater : .markAsRead
        guard let postUrl = AO3Endpoint.work(id: workID, route: route).url() else { throw AO3ClientError.invalidURL }
        
        _ = try await performFormPost(
            url: postUrl,
            formItems: [
                URLQueryItem(name: "authenticity_token", value: token),
                URLQueryItem(name: "_method", value: "patch")
            ],
            referer: getUrl
        )
        
        await self.cache.invalidate(containing: "readings")
        await self.cache.invalidate(containing: "\(workID)")
    }

    /// Removes a specific fic from the user's reading history.
    func deleteFromHistory(username: String, readingID: Int) async throws {
        
        guard let getUrl = AO3Endpoint.user(username: username, route: .history(showToRead: false)).url() else { throw AO3ClientError.invalidURL }
        let html = try await self.performRequest(url: getUrl, method: .get)
        let token = try AO3Parser.parseCSRFToken(from: html)
        
        guard let postUrl = AO3Endpoint.user(username: username, route: .historyItem(id: readingID)).url() else { throw AO3ClientError.invalidURL }
        
        _ = try await performFormPost(
            url: postUrl,
            formItems: [
                URLQueryItem(name: "authenticity_token", value: token),
                URLQueryItem(name: "_method", value: "delete"),
                URLQueryItem(name: "reading", value: String(readingID))
            ],
            referer: getUrl
        )
        
        await self.cache.invalidate(containing: "\(username)/readings")
    }

    /// Wipes the user's entire reading history.
    func clearHistory(username: String) async throws {
        
        guard let getUrl = AO3Endpoint.user(username: username, route: .history(showToRead: false)).url() else { throw AO3ClientError.invalidURL }
        let html = try await self.performRequest(url: getUrl, method: .get)
        let token = try AO3Parser.parseCSRFToken(from: html)
        
        guard let postUrl = AO3Endpoint.user(username: username, route: .clearHistory).url() else { throw AO3ClientError.invalidURL }
        
        _ = try await performFormPost(
            url: postUrl,
            formItems: [
                URLQueryItem(name: "authenticity_token", value: token)
            ],
            referer: getUrl
        )
        
        await self.cache.invalidate(containing: "\(username)/readings")
    }
}
