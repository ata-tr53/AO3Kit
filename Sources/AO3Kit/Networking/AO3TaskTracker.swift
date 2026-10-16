//
//  AO3TaskTracker.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 29.09.2026.
//


public actor AO3TaskTracker {
    
    private var inFlightTasks: [String: Any] = [:]
    
    public init() {}
    
    /// Executes a network task, or returns the result of an identical task if one is already running.
    public func track<T: Sendable>(key: String, operation: @Sendable @escaping () async throws -> T) async throws -> T {
        
        if let existingTask = inFlightTasks[key] as? Task<T, Error> {
            return try await existingTask.value
        }
        
        let newTask = Task<T, Error> {
            defer {
                Task { self.removeTask(forKey: key) }
            }
            return try await operation()
        }
        
        inFlightTasks[key] = newTask
        return try await newTask.value
    }
    
    private func removeTask(forKey key: String) {
        inFlightTasks.removeValue(forKey: key)
    }
}
