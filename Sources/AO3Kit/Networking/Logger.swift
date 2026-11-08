//
//  Logger.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 8.11.2026.
//

import Foundation
import OSLog

internal extension Logger {
    private static let subsystem = "com.AO3Kit"
    
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let cache = Logger(subsystem: subsystem, category: "Cache")
    static let parser = Logger(subsystem: subsystem, category: "Parser")
}
