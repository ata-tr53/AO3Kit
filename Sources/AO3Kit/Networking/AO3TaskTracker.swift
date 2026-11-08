//
//  AO3TaskTracker.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 29.09.2026.
//

import Foundation

public actor AO3TaskTracker {
    
    private struct InFlightEntry {
        let id: UUID
        let task: Any
    }
    
    private var inFlightTasks: [String: InFlightEntry] = [:]
    
    public init() {}
    
    /// Executes an async operation, or awaits an identical in-flight operation for the same key.
    public func track<T: Sendable>(
        key: String,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        if let existing = inFlightTasks[key]?.task as? Task<T, Error> {
            return try await existing.value
        }
        
        let taskID = UUID()
        let newTask = Task<T, Error> {
            try await operation()
        }
        
        inFlightTasks[key] = InFlightEntry(id: taskID, task: newTask)
        
        defer {
            if inFlightTasks[key]?.id == taskID {
                inFlightTasks.removeValue(forKey: key)
            }
        }
        
        return try await newTask.value
    }
}
