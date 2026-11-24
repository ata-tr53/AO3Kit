//
//  AO3Skin.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public enum AO3SkinType: String, Sendable, Codable, Hashable {
    case site
    case work
}

public struct AO3Skin: AO3SkinModel {
    public var id: Int
    public var title: String
    public var author: String?
    public var description: String?
    public var icon: AO3Image?
    public var type: AO3SkinType
    public var isActive: Bool

    public init(
        id: Int,
        title: String,
        author: String? = nil,
        description: String? = nil,
        icon: AO3Image? = nil,
        type: AO3SkinType = .site,
        isActive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.description = description
        self.icon = icon
        self.type = type
        self.isActive = isActive
    }
}

public struct AO3SkinDetails: AO3SkinModel {
    public var id: Int
    public var title: String
    public var author: String?
    public var description: String?
    public var css: String
    public var type: AO3SkinType
    public var media: [String]
    public var role: String?
    public var parentSkins: [String]
    public var isPublic: Bool
    public var isActive: Bool
    public var icon: AO3Image?

    public init(
        id: Int,
        title: String,
        author: String? = nil,
        description: String? = nil,
        css: String = "",
        type: AO3SkinType = .site,
        media: [String] = [],
        role: String? = nil,
        parentSkins: [String] = [],
        isPublic: Bool = false,
        isActive: Bool = false,
        icon: AO3Image? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.description = description
        self.css = css
        self.type = type
        self.media = media
        self.role = role
        self.parentSkins = parentSkins
        self.isPublic = isPublic
        self.isActive = isActive
        self.icon = icon
    }
}

public struct AO3SkinDraft: Sendable, Codable, Hashable {
    public var title: String
    public var css: String
    public var description: String
    public var type: AO3SkinType
    /// CSS media targets (e.g., `["all"]`, `["screen"]`, `["handheld"]`).
    public var media: [String]
    /// Skin role (e.g., `"user"`, `"override"`).
    public var role: String
    public var isPublic: Bool
    public var parentSkinTitles: [String]

    public init(
        title: String,
        css: String,
        description: String = "",
        type: AO3SkinType = .site,
        media: [String] = ["all"],
        role: String = "user",
        isPublic: Bool = false,
        parentSkinTitles: [String] = []
    ) {
        self.title = title
        self.css = css
        self.description = description
        self.type = type
        self.media = media
        self.role = role
        self.isPublic = isPublic
        self.parentSkinTitles = parentSkinTitles
    }
}
