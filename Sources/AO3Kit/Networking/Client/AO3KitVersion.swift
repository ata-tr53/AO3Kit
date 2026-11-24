//
//  AO3KitVersion.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

public struct AO3KitVersion: Sendable, Codable, Hashable, Comparable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?

    public init(_ major: Int, _ minor: Int, _ patch: Int, prerelease: String? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
    }

    public var description: String {
        if let prerelease, !prerelease.isEmpty {
            return "\(major).\(minor).\(patch)-\(prerelease)"
        }
        return "\(major).\(minor).\(patch)"
    }

    public static func < (lhs: AO3KitVersion, rhs: AO3KitVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        switch (lhs.prerelease, rhs.prerelease) {
        case (.some, .none): return true
        case (.none, .some): return false
        case (.some(let l), .some(let r)): return l < r
        case (.none, .none): return false
        }
    }
}
