//
//  AO3BookmarkDraft.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public enum AO3BookmarkTarget: Sendable, Equatable, Hashable {
    case work(id: Int)
    case series(id: Int)
    case externalWork(id: Int)

    public static func work<Fic: AO3FicModel>(_ fic: Fic) -> Self {
        .work(id: fic.id)
    }

    public static func series<Series: AO3SeriesModel>(_ series: Series) -> Self {
        .series(id: series.id)
    }

    public static func externalWork(_ work: AO3ExternalWork) -> Self {
        .externalWork(id: work.id)
    }

    internal var newFormEndpoint: AO3Endpoint {
        switch self {
        case .work(let id):
            return .work(id: id, route: .bookmarks(.new))
        case .series(let id):
            return .series(id: id, route: .bookmarks(.new))
        case .externalWork(let id):
            return .externalWork(.bookmarks(externalWorkID: id, action: .new))
        }
    }

    internal var cacheIdentifier: String {
        switch self {
        case .work(let id): return String(id)
        case .series(let id): return String(id)
        case .externalWork(let id): return String(id)
        }
    }
}

public struct AO3BookmarkDraft: Sendable, Equatable, Hashable {
    public var notes: String
    public var tags: [String]
    public var collections: [String]
    public var isPrivate: Bool
    public var isRec: Bool
    public var pseudName: String?

    public init(
        notes: String = "",
        tags: [String] = [],
        collections: [String] = [],
        isPrivate: Bool = false,
        isRec: Bool = false,
        pseudName: String? = nil
    ) {
        self.notes = notes
        self.tags = tags
        self.collections = collections
        self.isPrivate = isPrivate
        self.isRec = isRec
        self.pseudName = pseudName
    }
}
