//
//  AO3UserPreferences.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public struct AO3UserPreferences: Sendable, Codable, Hashable, AO3Response {
    public static var responseType: ResponseType { .preferences }

    public var preferenceID: Int

    // Privacy
    public var emailVisible: Bool
    public var dateOfBirthVisible: Bool
    public var minimizeSearchEngineVisibility: Bool
    public var disableShareLinks: Bool
    public var allowCollectionInvitation: Bool
    public var allowGifts: Bool

    // Display
    public var adult: Bool
    public var viewFullWorks: Bool
    public var hideWarnings: Bool
    public var hideFreeform: Bool
    public var disableWorkSkins: Bool
    public var hideAllHitCounts: Bool
    public var hideAllKudos: Bool
    public var hideAllBookmarks: Bool
    public var skinID: Int?
    public var timeZone: String?
    public var workTitleFormat: String?

    // Comments
    public var commentEmailsOff: Bool
    public var commentInboxOff: Bool
    public var commentCopyToSelfOff: Bool

    // Collections, Challenges & Gifts
    public var automaticallyApproveCollections: Bool
    public var collectionEmailsOff: Bool
    public var collectionInboxOff: Bool
    public var recipientEmailsOff: Bool

    // Misc
    public var historyEnabled: Bool
    public var firstLogin: Bool
    public var bannerSeen: Bool

    /// Preserves all parsed `preference[...]` form fields for lossless round-tripping.
    internal var rawFields: [String: String]

    public init(
        preferenceID: Int,
        emailVisible: Bool = false,
        dateOfBirthVisible: Bool = false,
        minimizeSearchEngineVisibility: Bool = false,
        disableShareLinks: Bool = false,
        allowCollectionInvitation: Bool = false,
        allowGifts: Bool = false,
        adult: Bool = false,
        viewFullWorks: Bool = false,
        hideWarnings: Bool = false,
        hideFreeform: Bool = false,
        disableWorkSkins: Bool = false,
        hideAllHitCounts: Bool = false,
        hideAllKudos: Bool = false,
        hideAllBookmarks: Bool = false,
        skinID: Int? = nil,
        timeZone: String? = nil,
        workTitleFormat: String? = nil,
        commentEmailsOff: Bool = false,
        commentInboxOff: Bool = false,
        commentCopyToSelfOff: Bool = false,
        automaticallyApproveCollections: Bool = false,
        collectionEmailsOff: Bool = false,
        collectionInboxOff: Bool = false,
        recipientEmailsOff: Bool = false,
        historyEnabled: Bool = true,
        firstLogin: Bool = false,
        bannerSeen: Bool = true
    ) {
        self.init(
            preferenceID: preferenceID,
            emailVisible: emailVisible,
            dateOfBirthVisible: dateOfBirthVisible,
            minimizeSearchEngineVisibility: minimizeSearchEngineVisibility,
            disableShareLinks: disableShareLinks,
            allowCollectionInvitation: allowCollectionInvitation,
            allowGifts: allowGifts,
            adult: adult,
            viewFullWorks: viewFullWorks,
            hideWarnings: hideWarnings,
            hideFreeform: hideFreeform,
            disableWorkSkins: disableWorkSkins,
            hideAllHitCounts: hideAllHitCounts,
            hideAllKudos: hideAllKudos,
            hideAllBookmarks: hideAllBookmarks,
            skinID: skinID,
            timeZone: timeZone,
            workTitleFormat: workTitleFormat,
            commentEmailsOff: commentEmailsOff,
            commentInboxOff: commentInboxOff,
            commentCopyToSelfOff: commentCopyToSelfOff,
            automaticallyApproveCollections: automaticallyApproveCollections,
            collectionEmailsOff: collectionEmailsOff,
            collectionInboxOff: collectionInboxOff,
            recipientEmailsOff: recipientEmailsOff,
            historyEnabled: historyEnabled,
            firstLogin: firstLogin,
            bannerSeen: bannerSeen,
            rawFields: [:]
        )
    }

    internal init(
        preferenceID: Int,
        emailVisible: Bool = false,
        dateOfBirthVisible: Bool = false,
        minimizeSearchEngineVisibility: Bool = false,
        disableShareLinks: Bool = false,
        allowCollectionInvitation: Bool = false,
        allowGifts: Bool = false,
        adult: Bool = false,
        viewFullWorks: Bool = false,
        hideWarnings: Bool = false,
        hideFreeform: Bool = false,
        disableWorkSkins: Bool = false,
        hideAllHitCounts: Bool = false,
        hideAllKudos: Bool = false,
        hideAllBookmarks: Bool = false,
        skinID: Int? = nil,
        timeZone: String? = nil,
        workTitleFormat: String? = nil,
        commentEmailsOff: Bool = false,
        commentInboxOff: Bool = false,
        commentCopyToSelfOff: Bool = false,
        automaticallyApproveCollections: Bool = false,
        collectionEmailsOff: Bool = false,
        collectionInboxOff: Bool = false,
        recipientEmailsOff: Bool = false,
        historyEnabled: Bool = true,
        firstLogin: Bool = false,
        bannerSeen: Bool = true,
        rawFields: [String: String]
    ) {
        self.preferenceID = preferenceID
        self.emailVisible = emailVisible
        self.dateOfBirthVisible = dateOfBirthVisible
        self.minimizeSearchEngineVisibility = minimizeSearchEngineVisibility
        self.disableShareLinks = disableShareLinks
        self.allowCollectionInvitation = allowCollectionInvitation
        self.allowGifts = allowGifts
        self.adult = adult
        self.viewFullWorks = viewFullWorks
        self.hideWarnings = hideWarnings
        self.hideFreeform = hideFreeform
        self.disableWorkSkins = disableWorkSkins
        self.hideAllHitCounts = hideAllHitCounts
        self.hideAllKudos = hideAllKudos
        self.hideAllBookmarks = hideAllBookmarks
        self.skinID = skinID
        self.timeZone = timeZone
        self.workTitleFormat = workTitleFormat
        self.commentEmailsOff = commentEmailsOff
        self.commentInboxOff = commentInboxOff
        self.commentCopyToSelfOff = commentCopyToSelfOff
        self.automaticallyApproveCollections = automaticallyApproveCollections
        self.collectionEmailsOff = collectionEmailsOff
        self.collectionInboxOff = collectionInboxOff
        self.recipientEmailsOff = recipientEmailsOff
        self.historyEnabled = historyEnabled
        self.firstLogin = firstLogin
        self.bannerSeen = bannerSeen
        self.rawFields = rawFields
    }

    internal func toFormItems() -> [URLQueryItem] {
        var fields = rawFields
        func setBool(_ key: String, _ value: Bool) {
            fields["preference[\(key)]"] = value ? "1" : "0"
        }

        setBool("email_visible", emailVisible)
        setBool("date_of_birth_visible", dateOfBirthVisible)
        setBool("minimize_search_engine_visibility", minimizeSearchEngineVisibility)
        setBool("disable_share_links", disableShareLinks)
        setBool("allow_collection_invitation", allowCollectionInvitation)
        setBool("allow_gifts", allowGifts)

        setBool("adult", adult)
        setBool("view_full_works", viewFullWorks)
        setBool("hide_warnings", hideWarnings)
        setBool("hide_freeform", hideFreeform)
        setBool("disable_work_skins", disableWorkSkins)
        setBool("hide_all_hit_counts", hideAllHitCounts)
        setBool("hide_all_kudos", hideAllKudos)
        setBool("hide_all_bookmarks", hideAllBookmarks)

        if let skinID {
            fields["preference[skin_id]"] = String(skinID)
        }
        if let timeZone {
            fields["preference[time_zone]"] = timeZone
        }
        if let workTitleFormat {
            fields["preference[work_title_format]"] = workTitleFormat
        }

        setBool("comment_emails_off", commentEmailsOff)
        setBool("comment_inbox_off", commentInboxOff)
        setBool("comment_copy_to_self_off", commentCopyToSelfOff)

        setBool("automatically_approve_collections", automaticallyApproveCollections)
        setBool("collection_emails_off", collectionEmailsOff)
        setBool("collection_inbox_off", collectionInboxOff)
        setBool("recipient_emails_off", recipientEmailsOff)

        setBool("history_enabled", historyEnabled)
        setBool("first_login", firstLogin)
        setBool("banner_seen", bannerSeen)

        return fields.sorted(by: { $0.key < $1.key }).map {
            URLQueryItem(name: $0.key, value: $0.value)
        }
    }
}
