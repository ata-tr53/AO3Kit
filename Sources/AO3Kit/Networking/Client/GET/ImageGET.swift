//
//  ImageGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 11.11.2026.
//

import Foundation

internal extension AO3Client {
    
    func fetchImageData(for url: URL, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> Data {
        let key = url.absoluteString
        let taskKey = "image_fetch_\(key)"
        
        var staleFallbackData: Data? = nil
        
        if fallbackStrategy != .throwError, let response: Data = await imageStore.data(forKey: key) {
            if fallbackStrategy != .bypassCache {
                return response
            } else {
                staleFallbackData = response
            }
        }
        
        do {
            let result = try await taskTracker.track(key: taskKey) {
                var request = URLRequest(url: url)
                request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
                
                let (data, response) = try await self.session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw AO3ClientError.invalidResponse
                }
                
                return data
            }
            await imageStore.store(result, forKey: key)
            return result
        } catch {
            if fallbackStrategy != .throwError, let staleData = staleFallbackData {
                return staleData
            }
            throw error
        }
    }
    
}
