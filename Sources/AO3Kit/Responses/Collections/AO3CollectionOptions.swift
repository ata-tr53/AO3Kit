//
//  AO3CollectionOptions.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//


public struct AO3CollectionOptions: OptionSet, Sendable, Codable, Hashable {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    /// Anyone can add works to this collection.
    public static let open       = AO3CollectionOptions(rawValue: 1 << 0) // 0001 (1)
    
    /// Submissions must be approved by a maintainer.
    public static let moderated  = AO3CollectionOptions(rawValue: 1 << 1) // 0010 (2)
    
    /// Works are hidden from the public (e.g., for Big Bangs).
    public static let unrevealed = AO3CollectionOptions(rawValue: 1 << 2) // 0100 (4)
    
    /// Authors of the works are hidden.
    public static let anonymous  = AO3CollectionOptions(rawValue: 1 << 3) // 1000 (8)
}
