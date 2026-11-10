//
//  AO3CollectionLink.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 15.09.2026.
//


public struct AO3CollectionLink: Identifiable, Sendable, Codable, AO3CollectionModel {
    public var id: String
    
    public var displayName: String
    
    public static var responseType: ResponseType { return .collection }
}
