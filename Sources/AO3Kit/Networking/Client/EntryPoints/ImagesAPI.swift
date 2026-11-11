//
//  ImagesAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 11.11.2026.
//

import Foundation

public struct AO3ImagesAPI: Sendable {
    internal let client: AO3Client
    
    /// Fetches raw image data for an `AO3Image`, returning cached data immediately if available.
    public func data(for image: AO3Image, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> Data {
        guard let url = image.url else {
            throw AO3ClientError.invalidURL
        }
        return try await data(for: url, fallbackStrategy: fallbackStrategy)
    }
    
    /// Fetches raw image data for any valid image URL, returning cached data immediately if available.
    public func data(for url: URL, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> Data {
        return try await client.fetchImageData(for: url, fallbackStrategy: fallbackStrategy)
    }
    
    /// Synchronously retrieves cached image data from memory or disk without hitting the network.
    public func cachedData(for image: AO3Image) async -> Data? {
        guard let url = image.url else { return nil }
        return await client.imageStore.data(forKey: url.absoluteString)
    }
    
    /// Clears both memory and disk image caches.
    public func clearCache() async {
        await client.imageStore.clearAll()
    }
}
