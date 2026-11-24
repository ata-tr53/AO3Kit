//
//  AO3Invitation.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public struct AO3InviteQueueStatus: Sendable, Codable, Hashable, AO3Response {
    public let email: String
    public let position: Int?
    public let totalInQueue: Int?
    public let estimatedDate: String?
    public let message: String

    public static var responseType: ResponseType { .invitation }

    public init(
        email: String,
        position: Int? = nil,
        totalInQueue: Int? = nil,
        estimatedDate: String? = nil,
        message: String
    ) {
        self.email = email
        self.position = position
        self.totalInQueue = totalInQueue
        self.estimatedDate = estimatedDate
        self.message = message
    }
}

public struct AO3Invitation: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public var id: String { token }
    public let token: String
    public let inviteeEmail: String?
    public let redeemedBy: String?
    public let sentAt: String?
    public let isUsed: Bool

    public var signupURL: URL? {
        AO3Endpoint.signup(invitationToken: token).url()
    }

    public static var responseType: ResponseType { .invitation }

    public init(
        token: String,
        inviteeEmail: String? = nil,
        redeemedBy: String? = nil,
        sentAt: String? = nil,
        isUsed: Bool = false
    ) {
        self.token = token
        self.inviteeEmail = inviteeEmail
        self.redeemedBy = redeemedBy
        self.sentAt = sentAt
        self.isUsed = isUsed
    }
}
