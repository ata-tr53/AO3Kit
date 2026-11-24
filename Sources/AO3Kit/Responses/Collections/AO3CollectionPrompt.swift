//
//  AO3CollectionPrompt.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 24.11.2026.
//

import Foundation

public struct AO3CollectionPrompt: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    public let title: String?
    public let requester: AO3AuthorLink?
    public let isAnonymous: Bool
    public let fandoms: [String]
    public let tags: [String]
    public let optionalTags: [String]
    public let descriptionHTML: String?
    public let claimCount: Int

    public static var responseType: ResponseType { .challenge }

    public init(
        id: Int,
        title: String? = nil,
        requester: AO3AuthorLink? = nil,
        isAnonymous: Bool = false,
        fandoms: [String] = [],
        tags: [String] = [],
        optionalTags: [String] = [],
        descriptionHTML: String? = nil,
        claimCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.requester = requester
        self.isAnonymous = isAnonymous
        self.fandoms = fandoms
        self.tags = tags
        self.optionalTags = optionalTags
        self.descriptionHTML = descriptionHTML
        self.claimCount = claimCount
    }
}
