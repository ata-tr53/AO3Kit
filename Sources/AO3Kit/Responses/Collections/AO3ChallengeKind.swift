//
//  AO3ChallengeKind.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

public enum AO3ChallengeKind: String, Sendable, Equatable, Hashable, CaseIterable {
    case all
    case giftExchange
    case promptMeme

    internal var endpoint: AO3Endpoint {
        switch self {
        case .all: return .collectionsIndex(.listChallenges)
        case .giftExchange: return .collectionsIndex(.listGEChallenges)
        case .promptMeme: return .collectionsIndex(.listPMChallenges)
        }
    }
}
