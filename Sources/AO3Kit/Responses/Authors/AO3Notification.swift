//
//  AO3Notification.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 3.10.2026.
//

import Foundation

public struct AO3Notification: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    
    public var user: AO3CommenterType
    public var commentLocation: AO3CommentLink
    
    public var relativeDate: String
    public var contentHTML: String
    
    public var isRead: Bool
    public var isRepliedTo: Bool
    
    public static var responseType: ResponseType { return .inboxNotification }
}
