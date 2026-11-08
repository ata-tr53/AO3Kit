//
//  AO3RateLimiter.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

public actor AO3RateLimiter {
    public static let shared = AO3RateLimiter()
    
    private var lastScheduledTime: Date = .distantPast
    private var penaltyUntil: Date = .distantPast
    private let minimumDelay: TimeInterval
    
    public init(minimumDelay: TimeInterval = 0.5) {
        self.minimumDelay = minimumDelay
    }
    
    /// Suspends the current task if a server penalty is active,
    /// or if the minimum delay hasn't passed since the last request.
    public func waitIfNeeded() async throws {
        let now = Date()
        
        let earliestAvailable = max(
            now,
            penaltyUntil,
            lastScheduledTime.addingTimeInterval(minimumDelay)
        )
        lastScheduledTime = earliestAvailable
        
        var targetTime = earliestAvailable
        while true {
            let currentNow = Date()
            let effectiveTarget = max(targetTime, penaltyUntil)
            let remainingDelay = effectiveTarget.timeIntervalSince(currentNow)
            
            guard remainingDelay > 0 else { break }
            
            try await Task.sleep(for: .seconds(remainingDelay))
            targetTime = effectiveTarget
        }
    }
    
    /// Extends the global network suspension until the specified duration passes.
    /// This is triggered when intercepting a 429 Retry-After header.
    public func imposePenalty(seconds: TimeInterval) {
        let newPenaltyTime = Date().addingTimeInterval(seconds)
        
        if newPenaltyTime > penaltyUntil {
            penaltyUntil = newPenaltyTime
        }
        if newPenaltyTime > lastScheduledTime {
            lastScheduledTime = newPenaltyTime
        }
    }
}
