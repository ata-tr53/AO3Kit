//
//  AO3AdminPost.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 15.09.2026.
//

import Foundation

public struct AO3AdminPost: Identifiable, Codable, Sendable, Hashable, AO3Response, AO3IconPresentable {
    public var id: Int
    
    public var title: String
    public var publishDate: Date
    public var tags: [String]
    
    public var displayImage: AO3Image?
    
    public var contentHTML: String
    
    public static var responseType: ResponseType { return .adminPost }
    public var icon: AO3Image? { return self.displayImage }
}
