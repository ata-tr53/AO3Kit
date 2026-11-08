//
//  AO3NetworkMonitor.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 8.11.2026.
//

import Foundation
import Network
import OSLog

internal actor AO3NetworkMonitor {
    static let shared = AO3NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private var isConnected: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.updateStatus(isSatisfied: path.status == .satisfied)
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    private func updateStatus(isSatisfied: Bool) {
        self.isConnected = isSatisfied
    }
    
    func requireConnection() throws {
        guard isConnected else {
            Logger.network.warning("Failing fast: No internet connection detected.")
            throw URLError(.notConnectedToInternet)
        }
    }
}
