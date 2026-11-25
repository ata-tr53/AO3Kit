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
    private let degradedMultiplier: Double
    private var currentStatus: AO3OperationalStatus = .operational
    
    public init(minimumDelay: TimeInterval = 0.5, degradedMultiplier: Double = 2.0) {
        self.minimumDelay = minimumDelay
        self.degradedMultiplier = degradedMultiplier
    }
    
    public func updateStatus(_ status: AO3OperationalStatus) {
        self.currentStatus = status
    }
    
    private var effectiveDelay: TimeInterval {
        switch currentStatus {
        case .degradedPerformance, .underMaintenance:
            return minimumDelay * degradedMultiplier
        case .operational, .notOperational, .unknown:
            return minimumDelay
        }
    }
    
    /// Suspends the current task if a server penalty is active,
    /// or if the effective delay hasn't passed since the last request.
    public func waitIfNeeded() async throws {
        try Task.checkCancellation()
        
        let now = Date()
        
        let earliestAvailable = max(
            now,
            penaltyUntil,
            lastScheduledTime.addingTimeInterval(effectiveDelay)
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
        guard seconds.isFinite, seconds > 0 else { return }
        
        let newPenaltyTime = Date().addingTimeInterval(seconds)
        
        if newPenaltyTime > penaltyUntil {
            penaltyUntil = newPenaltyTime
        }
        if newPenaltyTime > lastScheduledTime {
            lastScheduledTime = newPenaltyTime
        }
    }
}
