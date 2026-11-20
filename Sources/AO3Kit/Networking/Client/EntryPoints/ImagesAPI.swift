//
//  ImagesAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 11.11.2026.
//

import Foundation

public struct AO3ImagesAPI: Sendable {
    internal let client: AO3Client
    
    public var cache: AO3ImageCacheAPI { AO3ImageCacheAPI(client: self.client) }
    
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
    
    public func iconData<Item: AO3IconPresentable>(of item: Item, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> Data {
        return try await self.data(for: item.unwrappedIcon, fallbackStrategy: fallbackStrategy)
    }
}

public struct AO3ImageCacheAPI: Sendable {
    internal let client: AO3Client
    
    /// Synchronously retrieves cached image data from memory or disk without hitting the network.
    public func cachedData(forKey key: String) async -> Data? {
        return await client.imageStore.data(forKey: key)
    }
    
    /// Synchronously retrieves cached image data from memory or disk without hitting the network.
    public func cachedData(for image: AO3Image) async -> Data? {
        guard let url = image.url else { return nil }
        return await self.cachedData(forKey: url.absoluteString)
    }
    
    /// Synchronously retrieves cached image data from memory or disk without hitting the network.
    public func cachedData<Item: AO3IconPresentable>(for item: Item) async -> Data? {
        guard let url = item.icon?.url else { return nil }
        return await self.cachedData(forKey: url.absoluteString)
    }
    
    public func deleteCache(forKey key: String) async {
        await self.client.imageStore.delete(forKey: key)
    }
    
    public func deleteCache(for image: AO3Image) async {
        guard let url = image.url else { return }
        await self.client.imageStore.delete(forKey: url.absoluteString)
    }
    
    public func deleteCache<Item: AO3IconPresentable>(for item: Item) async {
        guard let url = item.icon?.url else { return }
        await self.client.imageStore.delete(forKey: url.absoluteString)
    }
    
    /// Clears both memory and disk image caches.
    public func clearCache() async {
        await client.imageStore.clearAll()
    }
}
