//
//  AO3CacheModels.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 29.09.2026.
//

import Foundation

public enum AO3CacheStrategy: Sendable {
    case memoryOnly
    case diskOnly
    case both
}

public enum AO3CacheExpirationStrategy: Sendable {
    /// The expired data is immediately purged from the cache, but returned one last time to the caller.
    case discard
    /// The expired data remains in the cache and will be returned on future calls until manually overwritten.
    case keepUntilReplaced
}

public enum AO3CacheState: Sendable {
    /// Data was found and is within its Time-To-Live (TTL).
    case upToDate
    /// Data was found but past its TTL. It remains in the cache based on the `keepUntilReplaced` strategy.
    case expired
    /// Data was found but past its TTL. It was successfully returned, but has now been wiped from the cache.
    case discarded
    /// No data was found for this key.
    case notFound
}

public struct AO3CacheResponse<T: Codable & Sendable>: Sendable {
    public let data: T?
    public let state: AO3CacheState
}

public enum AO3CacheFallbackStrategy: Sendable {
    /// If the network fetch fails, return the expired/stale cached data if available.
    case useCache
    /// If the network fetch fails, throw the error immediately, ignoring any stale cached data.
    case throwError
    /// Instantly returns cached data if it exists, completely ignoring its expiration date and skipping the network.
    case prioritiseCache
    /// Skips reading from the cache entirely and forces a network fetch. The new data will still be saved to the cache.
    case bypassCache
}
