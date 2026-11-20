//
//  AO3Language.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public struct AO3Language: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public var id: String
    public var name: String
    public var workCount: Int

    public var worksURL: URL? {
        AO3Endpoint.language(.works(languageID: id, action: .index)).url()
    }

    public static var responseType: ResponseType { .language }

    public init(id: String, name: String, workCount: Int) {
        self.id = id
        self.name = name
        self.workCount = workCount
    }
}
