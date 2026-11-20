//
//  AO3CoCreatorRequest.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

public struct AO3CoCreatorRequest: Identifiable, Sendable, Codable, AO3Response {
    public var id: Int
    public var creationTitle: String
    public var creationURL: URL?
    public var creationType: String
    public var pseudName: String?

    public static var responseType: ResponseType { .creatorship }

    public init(
        id: Int,
        creationTitle: String,
        creationURL: URL? = nil,
        creationType: String = "Work",
        pseudName: String? = nil
    ) {
        self.id = id
        self.creationTitle = creationTitle
        self.creationURL = creationURL
        self.creationType = creationType
        self.pseudName = pseudName
    }
}
