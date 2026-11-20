//
//  AO3WorkKudos.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public struct AO3WorkKudos: Sendable, Codable, Hashable, AO3Response {
    public var workID: Int
    public var users: [AO3AuthorLink]
    public var guestCount: Int

    public var totalDisplayed: Int {
        users.count + guestCount
    }

    public static var responseType: ResponseType { .kudos }

    public init(workID: Int, users: [AO3AuthorLink], guestCount: Int) {
        self.workID = workID
        self.users = users
        self.guestCount = guestCount
    }
}
