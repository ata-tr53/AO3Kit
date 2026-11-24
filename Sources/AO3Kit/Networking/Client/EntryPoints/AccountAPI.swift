//
//  AccountAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public struct AO3AccountAPI: Sendable {
    internal let client: AO3Client
    
    // MARK: Session State & Auth
    
    public var isLoggedIn: Bool { client.isLoggedIn }
    public var cachedUsername: String? { client.cachedUsername }
    
    @discardableResult
    public func login(username: String, password: String, rememberMe: Bool = true) async throws -> Bool {
        try await client.login(username: username, password: password, rememberMe: rememberMe)
    }
    
    public func logout() {
        client.logout()
    }
    
    public func userLink(fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AuthorLink {
        try await client.fetchCurrentUser(fallbackStrategy: fallbackStrategy)
    }
    
    public func profile(fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3AuthorMetadata {
        try await client.fetchCurrentUserProfile(fallbackStrategy: fallbackStrategy)
    }
    
    public func statistics(fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3UserStatistics {
        let username = try await client.resolveCurrentUsername()
        
        return try await client.fetchCachedItem(
            endpoint: .user(username: username, route: .stats),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseUserStatistics(html: html, username: username)
        }
        
    }
    
    // MARK: Inbox
    
    public func inboxPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3Notification> {
        let username = try await client.resolveCurrentUsername()
        
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .inbox),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseInbox
        )
        
    }
    
    public func allInbox(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3Notification] {
        let username = try await client.resolveCurrentUsername()
        
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .inbox),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseInbox
        )
        
    }
    
    public func manageInbox(commentIDs: [Int], action: AO3InboxAction) async throws {
        try await client.manageInbox(commentIDs: commentIDs, action: action)
    }
    
    // MARK: Reading History & Marked for Later
    
    public func historyPage(
        showMarkedForLater: Bool = false,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3HistoryFicPreview> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchUserHistoryPage(
            for: username,
            showMarkedForLater: showMarkedForLater,
            page: page,
            fallbackStrategy: fallbackStrategy
        )
    }
    
    public func allHistory(
        showMarkedForLater: Bool = false,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3HistoryFicPreview] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllUserHistory(
            for: username,
            showMarkedForLater: showMarkedForLater,
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }
    
    public func deleteFromHistory(readingID: Int) async throws {
        try await client.deleteFromHistory(readingID: readingID)
    }
    
    public func clearHistory() async throws {
        try await client.clearHistory()
    }
    
    // MARK: Subscriptions
    
    public func subscriptionsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3Subscription> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchSubscriptionsPage(for: username, page: page, fallbackStrategy: fallbackStrategy)
    }
    
    public func allSubscriptions(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3Subscription] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllSubscriptions(
            for: username,
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }
    
    public func toggleSubscription<Target: AO3Subscribable>(for target: Target) async throws {
        try await client.toggleSubscription(for: target)
    }
    
    public func addSubscription<Target: AO3Subscribable>(for target: Target) async throws {
        try await client.addSubscription(for: target)
    }
    
    public func deleteSubscription<Target: AO3Subscribable>(for target: Target) async throws {
        try await client.deleteSubscription(for: target)
    }
    
    public func deleteSubscription(for subscription: AO3Subscription) async throws {
        try await client.deleteSubscription(for: subscription)
    }

    public func deleteAllSubscriptions() async throws {
        try await client.deleteAllSubscriptions()
    }
    
    // MARK: Muted & Blocked Users
    
    public func moderationListPage(
        _ type: AO3ModerationListType,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3MutedBlockedLink> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: type.endpoint(for: username),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseMutedOrBlockedUsers
        )
    }
    
    public func allModerationList(
        _ type: AO3ModerationListType,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3MutedBlockedLink] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: type.endpoint(for: username),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseMutedOrBlockedUsers
        )
    }
    
    public func block<User: AO3Blockable>(_ target: User) async throws {
        try await client.blockUser(target: target)
    }
    
    public func unblock<User: AO3Blockable>(_ target: User) async throws {
        try await client.unblockUser(target: target)
    }
    
    public func mute<User: AO3Mutable>(_ target: User) async throws {
        try await client.muteUser(target: target)
    }
    
    public func unmute<User: AO3Mutable>(_ target: User) async throws {
        try await client.unmuteUser(target: target)
    }

    // MARK: Favorite Tags

    public func favoriteTags(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FavoriteTag] {
        try await client.fetchFavoriteTags(fallbackStrategy: fallbackStrategy)
    }

    public func addFavoriteTag(named tagName: String) async throws {
        try await client.addFavoriteTag(named: tagName)
    }

    public func addFavoriteTag<Tag: AO3TagModel>(_ tag: Tag) async throws {
        try await client.addFavoriteTag(named: tag.tagName)
    }

    public func removeFavoriteTag(named tagName: String) async throws {
        try await client.removeFavoriteTag(named: tagName)
    }

    public func removeFavoriteTag<Tag: AO3TagModel>(_ tag: Tag) async throws {
        try await client.removeFavoriteTag(named: tag.tagName)
    }

    public func removeFavoriteTag<Tag: AO3FavoritableTag>(_ tag: Tag) async throws {
        if let recordID = tag.favoriteRecordID {
            try await client.removeFavoriteTag(recordID: recordID)
        } else {
            try await client.removeFavoriteTag(named: tag.tagName)
        }
    }

    public func toggleFavoriteTag<Tag: AO3FavoritableTag>(_ tag: Tag) async throws {
        if tag.isFavorited {
            try await removeFavoriteTag(tag)
        } else {
            try await addFavoriteTag(tag)
        }
    }

    // MARK: Server-side Logout

    /// Logs out on the AO3 server (`DELETE /users/logout`) and clears local session cookies and caches.
    public func logoutFromServer() async throws {
        try await client.logoutFromServer()
    }

    // MARK: Site Skins

    public func publicSkinsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3Skin> {
        try await client.fetchPublicSkinsPage(page: page, fallbackStrategy: fallbackStrategy)
    }

    public func allPublicSkins(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3Skin] {
        try await client.fetchAllPublicSkins(
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }

    public func userSkinsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3Skin> {
        try await client.fetchUserSkinsPage(page: page, fallbackStrategy: fallbackStrategy)
    }

    public func allUserSkins(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3Skin] {
        try await client.fetchAllUserSkins(
            maxPages: maxPages,
            fallbackStrategy: fallbackStrategy,
            progressHandler: progressHandler
        )
    }

    public func setSkin(id skinID: Int) async throws {
        try await client.setSkin(id: skinID)
    }

    public func setSkin<Skin: AO3SkinModel>(_ skin: Skin) async throws {
        try await client.setSkin(id: skin.id)
    }

    public func unsetSkin() async throws {
        try await client.unsetSkin()
    }

    public func skinDetails(
        id skinID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3SkinDetails {
        try await client.fetchSkinDetails(id: skinID, fallbackStrategy: fallbackStrategy)
    }

    public func skinDetails<Skin: AO3SkinModel>(
        for skin: Skin,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3SkinDetails {
        try await client.fetchSkinDetails(id: skin.id, fallbackStrategy: fallbackStrategy)
    }

    public func previewSkin(id skinID: Int) async throws {
        try await client.previewSkin(id: skinID)
    }

    public func previewSkin<Skin: AO3SkinModel>(_ skin: Skin) async throws {
        try await client.previewSkin(id: skin.id)
    }

    @discardableResult
    public func createSkin(_ draft: AO3SkinDraft) async throws -> Int? {
        try await client.createSkin(draft)
    }

    public func updateSkin(id skinID: Int, draft: AO3SkinDraft) async throws {
        try await client.updateSkin(id: skinID, draft: draft)
    }

    public func updateSkin<Skin: AO3SkinModel>(_ skin: Skin, draft: AO3SkinDraft) async throws {
        try await client.updateSkin(id: skin.id, draft: draft)
    }

    public func deleteSkin(id skinID: Int) async throws {
        try await client.deleteSkin(id: skinID)
    }

    public func deleteSkin<Skin: AO3SkinModel>(_ skin: Skin) async throws {
        try await client.deleteSkin(id: skin.id)
    }

    // MARK: User Preferences

    public func preferences(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3UserPreferences {
        try await client.fetchUserPreferences(fallbackStrategy: fallbackStrategy)
    }

    public func updatePreferences(_ preferences: AO3UserPreferences) async throws {
        try await client.updateUserPreferences(preferences)
    }

    // MARK: Author & User Dashboard (Drafts, Collected Works, Collections, Related Works, Creatorships)

    public func draftsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicPreview> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .worksSub(.drafts)),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
    }

    public func allDrafts(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicPreview] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .worksSub(.drafts)),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
    }

    public func collectedWorksPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicPreview> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .worksSub(.collected)),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
    }

    public func allCollectedWorks(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicPreview] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .worksSub(.collected)),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
    }

    public func collectionsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3CollectionPreview> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .collections),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
    }

    public func allCollections(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionPreview] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .collections),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseCollectionPreviews
        )
    }

    public func relatedWorks(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3RelatedWork] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchRelatedWorks(for: username, fallbackStrategy: fallbackStrategy)
    }

    public func approveRelatedWork(id relatedWorkID: Int) async throws {
        try await client.approveRelatedWork(id: relatedWorkID)
    }

    public func approveRelatedWork(_ relatedWork: AO3RelatedWork) async throws {
        try await client.approveRelatedWork(id: relatedWork.id)
    }

    public func removeRelatedWork(id relatedWorkID: Int) async throws {
        try await client.removeRelatedWork(id: relatedWorkID)
    }

    public func removeRelatedWork(_ relatedWork: AO3RelatedWork) async throws {
        try await client.removeRelatedWork(id: relatedWork.id)
    }

    public func coCreatorRequests(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3CoCreatorRequest] {
        try await client.fetchCoCreatorRequests(fallbackStrategy: fallbackStrategy)
    }

    public func respondToCoCreatorRequests(ids: [Int], accept: Bool) async throws {
        try await client.respondToCoCreatorRequests(ids: ids, accept: accept)
    }

    public func respondToCoCreatorRequest(_ request: AO3CoCreatorRequest, accept: Bool) async throws {
        try await client.respondToCoCreatorRequests(ids: [request.id], accept: accept)
    }

    // MARK: Gifts

    /// Toggles whether a gift work is refused or accepted (`POST /gifts/:id/toggle_rejected`).
    public func toggleGiftRejected(giftID: Int) async throws {
        try await client.toggleGiftRejected(giftID: giftID)
    }

    // MARK: Profile & Pseuds Editing

    public func profileDraft() async throws -> AO3ProfileDraft {
        try await client.fetchProfileDraft()
    }

    public func updateProfile(_ draft: AO3ProfileDraft) async throws {
        try await client.updateProfile(draft)
    }

    public func createPseud(_ draft: AO3PseudDraft) async throws {
        try await client.createPseud(draft)
    }

    public func updatePseud(named currentName: String, draft: AO3PseudDraft) async throws {
        try await client.updatePseud(named: currentName, draft: draft)
    }

    public func updatePseud(_ pseud: AO3AuthorPseudLink, draft: AO3PseudDraft) async throws {
        try await client.updatePseud(named: pseud.pseudName, draft: draft)
    }

    public func deletePseud(named name: String) async throws {
        try await client.deletePseud(named: name)
    }

    public func deletePseud(_ pseud: AO3AuthorPseudLink) async throws {
        try await client.deletePseud(named: pseud.pseudName)
    }

    // MARK: Collection Items (Approving / Rejecting Collection Invites)

    public func collectionItemsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3CollectionItem> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .collectionItems(.index)),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserCollectionItems
        )
    }

    public func allCollectionItems(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3CollectionItem] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .collectionItems(.index)),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserCollectionItems
        )
    }

    public func updateCollectionItems(
        decisions: [Int: AO3CollectionItemStatus] = [:],
        removeIDs: [Int] = []
    ) async throws {
        try await client.updateUserCollectionItems(decisions: decisions, removeIDs: removeIDs)
    }

    // MARK: Credentials & Password Reset

    public func requestPasswordReset(loginOrEmail: String) async throws {
        try await client.requestPasswordReset(loginOrEmail: loginOrEmail)
    }

    public func changePassword(currentPassword: String, newPassword: String) async throws {
        try await client.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }

    public func changeEmail(currentPassword: String, newEmail: String) async throws {
        try await client.changeEmail(currentPassword: currentPassword, newEmail: newEmail)
    }

    public func changeUsername(currentPassword: String, newUsername: String) async throws {
        try await client.changeUsername(currentPassword: currentPassword, newUsername: newUsername)
    }

    public func reconfirmEmail() async throws {
        try await client.reconfirmEmail()
    }

    // MARK: Invite Queue & Invitations

    public func requestInvitation(email: String) async throws {
        try await client.requestInvitation(email: email)
    }

    public func inviteQueueStatus(forEmail email: String) async throws -> AO3InviteQueueStatus {
        try await client.fetchInviteQueueStatus(email: email)
    }

    public func invitations(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Invitation] {
        try await client.fetchUserInvitations(fallbackStrategy: fallbackStrategy)
    }

    public func inviteFriend(email: String) async throws {
        try await client.inviteFriend(email: email)
    }

    public func requestUserInvitations(quantity: Int, reason: String) async throws {
        try await client.requestUserInvitations(quantity: quantity, reason: reason)
    }

    // MARK: Challenge Dashboard (Signups, Assignments, Claims, Tag Sets, Nominations)

    public func signupsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3ChallengeSignup> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .signups),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserSignups
        )
    }

    public func allSignups(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3ChallengeSignup] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .signups),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserSignups
        )
    }

    public func assignmentsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3ChallengeAssignment> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .assignments),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserAssignments
        )
    }

    public func allAssignments(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3ChallengeAssignment] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .assignments),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserAssignments
        )
    }

    public func claimsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3ChallengeClaim> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .claims),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserClaims
        )
    }

    public func allClaims(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3ChallengeClaim] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .claims),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserClaims
        )
    }

    public func tagSetsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3TagSetPreview> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .tagSets),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseTagSets
        )
    }

    public func allTagSets(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3TagSetPreview] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .tagSets),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseTagSets
        )
    }

    public func nominationsPage(
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3TagSetNomination> {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchPaginated(
            endpoint: .user(username: username, route: .nominations),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserNominations
        )
    }

    public func allNominations(
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3TagSetNomination] {
        let username = try await client.resolveCurrentUsername()
        return try await client.fetchAllItems(
            endpoint: .user(username: username, route: .nominations),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseUserNominations
        )
    }
}
