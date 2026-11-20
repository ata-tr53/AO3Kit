//
//  AO3RelatedWork.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

public struct AO3RelatedWork: Identifiable, Sendable, Codable, AO3Response {
    public var id: Int
    public var workTitle: String
    public var workURL: URL?
    public var authorName: String?
    public var parentTitle: String?
    public var parentURL: URL?
    public var isTranslation: Bool
    public var isApproved: Bool

    public static var responseType: ResponseType { .relatedWork }

    public init(
        id: Int,
        workTitle: String,
        workURL: URL? = nil,
        authorName: String? = nil,
        parentTitle: String? = nil,
        parentURL: URL? = nil,
        isTranslation: Bool = false,
        isApproved: Bool = false
    ) {
        self.id = id
        self.workTitle = workTitle
        self.workURL = workURL
        self.authorName = authorName
        self.parentTitle = parentTitle
        self.parentURL = parentURL
        self.isTranslation = isTranslation
        self.isApproved = isApproved
    }
}
