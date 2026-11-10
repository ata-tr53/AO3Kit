//
//  MutedBlockedPOST.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 6.10.2026.
//

import Foundation
import SwiftSoup

internal extension AO3Client {
    
    private func executeActionViaConfirmPage(confirmURLString: String) async throws {
        guard let confirmURL = URL(string: confirmURLString) else {
            throw AO3ClientError.invalidURL
        }
        
        let html = try await performRequest(url: confirmURL, method: .get)
        let doc = try SwiftSoup.parse(html)
        
        guard let form = try doc.select("form:has(input[name=authenticity_token])").first() else {
            throw AO3ClientError.invalidData
        }
        
        let actionPath = try form.attr("action")
        let actionURLString = actionPath.hasPrefix("http") ? actionPath : "https://archiveofourown.org" + (actionPath.hasPrefix("/") ? "" : "/") + actionPath
        guard let actionURL = URL(string: actionURLString) else {
            throw AO3ClientError.invalidURL
        }
        
        var formItems: [URLQueryItem] = []

        for input in try form.select("input[type=hidden]").array() {
            let name = try input.attr("name")
            if !name.isEmpty {
                formItems.append(URLQueryItem(name: name, value: try input.attr("value")))
            }
        }

        if let submitBtn = try form.select("input[type=submit]").first() {
            let name = try submitBtn.attr("name")
            if !name.isEmpty {
                formItems.append(URLQueryItem(name: name, value: try submitBtn.attr("value")))
            }
        }

        _ = try await performFormPost(
            url: actionURL,
            formItems: formItems,
            referer: confirmURL
        )
    }
    
    
    
    // MARK: - Block / Unblock POST
    
    func blockUser<User: AO3Blockable>(target: User) async throws {
        let currentUser = try await resolveCurrentUsername()
        
        await self.cache.invalidate(containing: target.username)
        await self.cache.invalidate(containing: "blocked")
        
        try await self.blockUser(currentUser: currentUser, targetUser: target.username)
    }
    
    func unblockUser<User: AO3Blockable>(target: User) async throws {
        guard let actionID = target.unblockActionID else { throw AO3ClientError.invalidEndpoint }
        let currentUser = try await resolveCurrentUsername()
        
        await self.cache.invalidate(containing: target.username)
        await self.cache.invalidate(containing: "blocked")
        
        try await self.unblockUser(currentUser: currentUser, actionID: actionID)
    }
    
    private func blockUser(currentUser: String, targetUser: String) async throws {
        let urlString = "https://archiveofourown.org/users/\(currentUser)/blocked/users/confirm_block?blocked_id=\(targetUser)"
        try await executeActionViaConfirmPage(confirmURLString: urlString)
    }
    
    private func unblockUser(currentUser: String, actionID: Int) async throws {
        let urlString = "https://archiveofourown.org/users/\(currentUser)/blocked/users/\(actionID)/confirm_unblock"
        try await executeActionViaConfirmPage(confirmURLString: urlString)
    }
    
    // MARK: - Mute / Unmute POST
    
    func muteUser<User: AO3Mutable>(target: User) async throws {
        let currentUser = try await resolveCurrentUsername()
        
        await self.cache.invalidate(containing: target.username)
        await self.cache.invalidate(containing: "muted")
        
        try await self.muteUser(currentUser: currentUser, targetUser: target.username)
    }
    
    func unmuteUser<User: AO3Mutable>(target: User) async throws {
        guard let actionID = target.unmuteActionID else { throw AO3ClientError.invalidEndpoint }
        let currentUser = try await resolveCurrentUsername()
        
        await self.cache.invalidate(containing: target.username)
        await self.cache.invalidate(containing: "muted")
        
        try await self.unmuteUser(currentUser: currentUser, actionID: actionID)
    }
    
    private func muteUser(currentUser: String, targetUser: String) async throws {
        let urlString = "https://archiveofourown.org/users/\(currentUser)/muted/users/confirm_mute?muted_id=\(targetUser)"
        try await executeActionViaConfirmPage(confirmURLString: urlString)
    }
    
    private func unmuteUser(currentUser: String, actionID: Int) async throws {
        let urlString = "https://archiveofourown.org/users/\(currentUser)/muted/users/\(actionID)/confirm_unmute"
        try await executeActionViaConfirmPage(confirmURLString: urlString)
    }
}
