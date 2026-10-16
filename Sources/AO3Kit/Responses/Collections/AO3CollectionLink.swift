//
//  AO3CollectionLink.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 15.09.2026.
//


public struct AO3CollectionLink: Identifiable, Sendable, Codable, AO3Response {
    public var id: String
    public var name: String
    
    public static var responseType: ResponseType { return .collection }
}
