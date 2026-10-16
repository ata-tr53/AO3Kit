//
//  AO3PaginatedResult.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation

public struct AO3PaginatedResult<T: Sendable & Codable & AO3Response>: Sendable, Codable, AO3Response {
    public let items: [T]
    public let currentPage: Int
    public let totalPages: Int
    
    public var hasNextPage: Bool {
        return currentPage < totalPages
    }
    
    public static var responseType: ResponseType { return T.responseType}
}
