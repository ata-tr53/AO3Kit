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

public struct AO3Skin: Identifiable, Sendable, Codable, AO3Response, AO3IconPresentable {
    public var id: Int
    public var title: String
    public var author: String?
    public var description: String?
    public var icon: AO3Image?
    public var type: AO3SkinType
    public var isActive: Bool

    public var url: URL? {
        AO3Endpoint.skin(.show(id: id)).url()
    }

    public static var responseType: ResponseType { .skin }

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
