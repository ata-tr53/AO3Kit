//
//  AO3ProfileDraft.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public struct AO3ProfileDraft: Sendable, Codable, Hashable {
    /// Profile header title (`profile_attributes[title]`).
    public var title: String
    /// "About Me" biography text/HTML (`profile_attributes[about_me]`).
    public var aboutMe: String

    public init(title: String = "", aboutMe: String = "") {
        self.title = title
        self.aboutMe = aboutMe
    }
}

public struct AO3PseudDraft: Sendable, Codable, Hashable {
    public var name: String
    public var description: String
    public var isDefault: Bool
    public var iconAltText: String
    public var iconCommentText: String
    /// Set to `true` when editing a pseud to remove its existing icon (`pseud[delete_icon]=1`).
    public var deleteIcon: Bool

    public init(
        name: String,
        description: String = "",
        isDefault: Bool = false,
        iconAltText: String = "",
        iconCommentText: String = "",
        deleteIcon: Bool = false
    ) {
        self.name = name
        self.description = description
        self.isDefault = isDefault
        self.iconAltText = iconAltText
        self.iconCommentText = iconCommentText
        self.deleteIcon = deleteIcon
    }
}
