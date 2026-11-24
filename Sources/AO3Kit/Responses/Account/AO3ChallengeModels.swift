//
//  AO3ChallengeModels.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public struct AO3ChallengeSignup: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    public let collectionID: String?
    public let collectionTitle: String
    public let url: URL?

    public static var responseType: ResponseType { .challenge }

    public init(id: Int, collectionID: String? = nil, collectionTitle: String, url: URL? = nil) {
        self.id = id
        self.collectionID = collectionID
        self.collectionTitle = collectionTitle
        self.url = url
    }
}

public struct AO3ChallengeAssignment: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    public let collectionID: String?
    public let collectionTitle: String
    public let recipient: String?
    public let dueDate: String?
    public let status: String?
    public let url: URL?

    public static var responseType: ResponseType { .challenge }

    public init(
        id: Int,
        collectionID: String? = nil,
        collectionTitle: String,
        recipient: String? = nil,
        dueDate: String? = nil,
        status: String? = nil,
        url: URL? = nil
    ) {
        self.id = id
        self.collectionID = collectionID
        self.collectionTitle = collectionTitle
        self.recipient = recipient
        self.dueDate = dueDate
        self.status = status
        self.url = url
    }
}

public struct AO3ChallengeClaim: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    public let collectionID: String?
    public let collectionTitle: String
    public let promptTitle: String?
    public let requester: String?
    public let isFulfilled: Bool
    public let url: URL?

    public static var responseType: ResponseType { .challenge }

    public init(
        id: Int,
        collectionID: String? = nil,
        collectionTitle: String,
        promptTitle: String? = nil,
        requester: String? = nil,
        isFulfilled: Bool = false,
        url: URL? = nil
    ) {
        self.id = id
        self.collectionID = collectionID
        self.collectionTitle = collectionTitle
        self.promptTitle = promptTitle
        self.requester = requester
        self.isFulfilled = isFulfilled
        self.url = url
    }
}

public struct AO3TagSetPreview: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    public let title: String
    public let owners: [String]
    public let description: String?
    public let isNominationOpen: Bool

    public var url: URL? {
        AO3Endpoint.tagSet(.show(id: id)).url()
    }

    public static var responseType: ResponseType { .tagSet }

    public init(
        id: Int,
        title: String,
        owners: [String] = [],
        description: String? = nil,
        isNominationOpen: Bool = false
    ) {
        self.id = id
        self.title = title
        self.owners = owners
        self.description = description
        self.isNominationOpen = isNominationOpen
    }
}

public struct AO3TagSetNomination: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    public let tagSetID: Int?
    public let tagSetTitle: String
    public let url: URL?

    public static var responseType: ResponseType { .tagSet }

    public init(id: Int, tagSetID: Int? = nil, tagSetTitle: String, url: URL? = nil) {
        self.id = id
        self.tagSetID = tagSetID
        self.tagSetTitle = tagSetTitle
        self.url = url
    }
}
