//
//  AO3Response.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 7.10.2026.
//

public protocol AO3Response: Sendable, Codable, Hashable {
    static var responseType: ResponseType { get }
}

public extension AO3Response {
    var responseType: ResponseType {
        return Self.responseType
    }
}


public enum ResponseType: String, Codable, Sendable {
    case user = "User"
    case work = "Work"
    case series = "Series"
    case adminPost = "Admin Post"
    case inboxNotification = "Notification"
    case bookmark = "Bookmark"
    case collection = "Collection"
    case commentThread = "Comment Thread"
    case comment = "Comment"
    case chapter = "Chapter"
    case stats = "Stats"
    case subscription = "Subscription"
    case autocomplete = "Autocomplete"
    case tag = "Tag"
    case skin = "Skin"
    case kudos = "Kudos"
    case preferences = "Preferences"
    case language = "Language"
    case media = "Media"
    case download = "Download"
    case relatedWork = "Related Work"
    case creatorship = "Creatorship"
}

public extension Array where Element == any AO3Response {
    
    var responseTypes: [ResponseType] {
        return map(\.responseType)
    }
    
    var responseType: ResponseType? {
        return first?.responseType
    }
}
