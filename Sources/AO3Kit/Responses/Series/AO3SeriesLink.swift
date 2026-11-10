//
//  AO3SeriesLink.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 15.09.2026.
//


public struct AO3SeriesLink: Identifiable, Sendable, Codable, AO3SeriesModel {
    public var id: Int
    public var name: String
    public var partIndex: Int?
    
    public static var responseType: ResponseType { return .series }
}
