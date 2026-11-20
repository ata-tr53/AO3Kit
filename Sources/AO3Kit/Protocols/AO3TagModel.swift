//
//  AO3TagModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

public protocol AO3TagModel: Identifiable, AO3Response {
    var tagName: String { get }
}

public extension AO3TagModel {
    var url: URL? { AO3Endpoint.tag(name: tagName, route: .works).url() }
    static var responseType: ResponseType { .tag }
}

public protocol AO3FavoritableTag: AO3TagModel {
    var favoriteRecordID: Int? { get set }
}

public extension AO3FavoritableTag {
    var isFavorited: Bool { favoriteRecordID != nil }
}

// MARK: - Default Conformances

extension AO3TagSearchResult: AO3TagModel {
    public var tagName: String { name }
}
