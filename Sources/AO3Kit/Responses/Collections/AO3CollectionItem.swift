//
//  AO3CollectionItem.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public enum AO3CollectionItemStatus: String, Sendable, Codable, Hashable {
    case unreviewed = "unreviewed"
    case approved = "approved"
    case rejected = "rejected"
}

public struct AO3CollectionItem: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    public let collectionID: String?
    public let collectionTitle: String
    public let workID: Int?
    public let workTitle: String
    public let status: AO3CollectionItemStatus

    public static var responseType: ResponseType { .collection }

    public init(
        id: Int,
        collectionID: String? = nil,
        collectionTitle: String,
        workID: Int? = nil,
        workTitle: String,
        status: AO3CollectionItemStatus = .unreviewed
    ) {
        self.id = id
        self.collectionID = collectionID
        self.collectionTitle = collectionTitle
        self.workID = workID
        self.workTitle = workTitle
        self.status = status
    }
}
