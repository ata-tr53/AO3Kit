//
//  AO3Subscription.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 5.10.2026.
//

import Foundation

public enum AO3SubscriptionType: Codable, Hashable, Sendable {
    case user(link: AO3AuthorLink)
    case work(id: Int, authors: [AO3AuthorLink])
    case series(id: Int, creators: [AO3AuthorLink])
    
    public var typeName: LocalizedStringResource {
        switch self {
        case .user: return "User"
        case .work: return "Work"
        case .series: return "Series"
        }
    }
    
    public var responseType: ResponseType {
        switch self {
        case .user: return .user
        case .work: return .work
        case .series: return .series
        }
    }
}

public struct AO3Subscription: Identifiable, Sendable, Codable, Hashable, AO3Response {
    /// The database ID of the subscription itself.
    public let id: Int
    
    /// The name of the subscribed item.
    public var name: String
    
    /// The parsed target type.
    public var type: AO3SubscriptionType
    
    public static var responseType: ResponseType { .subscription }
}
