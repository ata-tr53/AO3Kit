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
        
        let parameters = [
            "utf8": "✓",
            "authenticity_token": csrfToken,
            "user[login]": username,
            "user[password]": password,
            "user[remember_me]": "\(rememberMe ? 1 : 0)",
            "commit": "Log In"
        ]
        
        let postString = parameters.map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            return "\(escapedKey)=\(escapedValue)"
        }.joined(separator: "&")
        
        guard let postData = postString.data(using: .utf8) else {
            throw AO3ClientError.invalidData
        }
        
        let customHeaders = [
            "Referer": loginURL.absoluteString
        ]
        
        let responseHTML = try await performRequest(url: loginURL, method: .post, body: postData, headers: customHeaders)
        
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
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "authenticity_token", value: token),
            URLQueryItem(name: "_method", value: "patch")
        ]
        
        let bodyString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        let bodyData = Data(bodyString.utf8)
        let headers = ["Content-Type": "application/x-www-form-urlencoded"]
        
        _ = try await self.performRequest(
            url: postUrl,
            method: .post,
            body: bodyData,
            headers: headers
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
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "authenticity_token", value: token),
            URLQueryItem(name: "_method", value: "delete"),
            URLQueryItem(name: "reading", value: String(readingID))
        ]
        
        let bodyString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        let bodyData = Data(bodyString.utf8)
        let headers = ["Content-Type": "application/x-www-form-urlencoded"]
        
        _ = try await self.performRequest(
            url: postUrl,
            method: .post,
            body: bodyData,
            headers: headers
        )
        
        await self.cache.invalidate(containing: "\(username)/readings")
    }

    /// Wipes the user's entire reading history.
    func clearHistory(username: String) async throws {
        
        guard let getUrl = AO3Endpoint.user(username: username, route: .history(showToRead: false)).url() else { throw AO3ClientError.invalidURL }
        let html = try await self.performRequest(url: getUrl, method: .get)
        let token = try AO3Parser.parseCSRFToken(from: html)
        
        guard let postUrl = AO3Endpoint.user(username: username, route: .clearHistory).url() else { throw AO3ClientError.invalidURL }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "authenticity_token", value: token)
        ]
        
        let bodyString = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        let bodyData = Data(bodyString.utf8)
        let headers = ["Content-Type": "application/x-www-form-urlencoded"]
        
        _ = try await self.performRequest(
            url: postUrl,
            method: .post,
            body: bodyData,
            headers: headers
        )
        
        await self.cache.invalidate(containing: "\(username)/readings")
    }
}
