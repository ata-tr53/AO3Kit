//
//  AO3AuthorPseudLink.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

public struct AO3AuthorPseudLink: Codable, Sendable, Identifiable, AO3AuthorModel {
    public var username: String { self.pseudName }
    public var id: String { self.pseudName }
    
    public var pseudName: String
    
    public var summary: String?
    
    public var icon: AO3Image?
    public var workCount: Int?
    
    public static var responseType: ResponseType { return .user }
    
}
