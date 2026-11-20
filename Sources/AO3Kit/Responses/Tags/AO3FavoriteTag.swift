//
//  AO3FavoriteTag.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public struct AO3FavoriteTag: Identifiable, Sendable, Codable, AO3FavoritableTag {
    public var id: String { name }
    public var tagName: String { name }
    public var name: String
    public var favoriteRecordID: Int?

    public init(name: String, favoriteRecordID: Int? = nil) {
        self.name = name
        self.favoriteRecordID = favoriteRecordID
    }
}
