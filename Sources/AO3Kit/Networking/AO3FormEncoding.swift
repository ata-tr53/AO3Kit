//
//  AO3FormEncoding.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 8.11.2026.
//

import Foundation

internal extension CharacterSet {
    /// RFC 3986 unreserved characters safe for application/x-www-form-urlencoded keys and values.
    /// Ensures '+', '/', '=', '&', and '%' inside Rails CSRF tokens are always percent-encoded.
    static let ao3FormURLEncodedAllowed = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )
}

internal extension Sequence where Element == URLQueryItem {
    func formURLEncodedData() throws -> Data {
        let encodedPairs = self.map { item -> String in
            let encodedName = item.name.addingPercentEncoding(withAllowedCharacters: .ao3FormURLEncodedAllowed) ?? ""
            let encodedValue = (item.value ?? "").addingPercentEncoding(withAllowedCharacters: .ao3FormURLEncodedAllowed) ?? ""
            return "\(encodedName)=\(encodedValue)"
        }
        guard let data = encodedPairs.joined(separator: "&").data(using: .utf8) else {
            throw AO3ClientError.invalidData
        }
        return data
    }
}

internal extension Dictionary where Key == String, Value == String {
    func formURLEncodedData() throws -> Data {
        try self.map { URLQueryItem(name: $0.key, value: $0.value) }.formURLEncodedData()
    }
}
