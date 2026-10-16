//
//  AO3RateLimiter.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

public actor AO3RateLimiter {
    public static let shared = AO3RateLimiter()
    
    private var lastRequestTime: Date = .distantPast
    private let minimumDelay: TimeInterval
    
    public init(minimumDelay: TimeInterval = 0.5) {
        self.minimumDelay = minimumDelay
    }
    
    /// Suspends the current task if the minimum delay hasn't passed since the last request.
    public func waitIfNeeded() async throws {
        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
        
        if timeSinceLastRequest < minimumDelay {
            let delay = minimumDelay - timeSinceLastRequest
            
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        lastRequestTime = Date()
    }
}
