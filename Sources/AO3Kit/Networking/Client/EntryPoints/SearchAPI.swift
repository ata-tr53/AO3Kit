//
//  SearchAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public struct SearchAPI: Sendable {
    internal let client: AO3Client
    
    public func autocomplete(type: AO3AutocompleteType, for: String) async throws -> AO3AdminPost {
        throw AO3ClientError.notImplemented
    }
    
}

public enum AO3AutocompleteType: Sendable, Equatable {
    case tag
    case fandom
    case character
    case relationship
    case freeform
}
