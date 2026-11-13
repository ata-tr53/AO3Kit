//
//  AO3Image.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 12.11.2026.
//

import Foundation


public struct AO3Image: Identifiable, Sendable, Codable, Hashable {
    public var description: String?
    public var source: String
    
    public var url: URL? { return URL(string: self.source) }
    
    public var id: String { self.source }
    
    public var isDefault: Bool {
        self.source.contains("/images/skins/iconsets/default/icon_user.png")
    }
}


public extension AO3Image {
    static let defaultLight: AO3Image = AO3Image(source: "https://archiveofourown.org/images/skins/iconsets/default/icon_user.png")
}
