//
//  AO3DateFormatter.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation
import Synchronization

internal struct AO3DateParser: Sendable, ~Copyable {
    private let lock: Mutex<DateFormatter>
    
    init(format: String, timeZone: TimeZone? = TimeZone(secondsFromGMT: 0)) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let timeZone {
            formatter.timeZone = timeZone
        }
        formatter.dateFormat = format
        self.lock = Mutex(formatter)
    }
    
    func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return lock.withLock { formatter in
            formatter.date(from: string)
        }
    }
}

internal extension DateFormatter {
    /// Format: `2026-09-14`
    static let ao3DateFormatter = AO3DateParser(
        format: "yyyy-MM-dd",
        timeZone: TimeZone(secondsFromGMT: 0)
    )
    
    /// Format: `Mon 14 Sep 2026 11:28AM UTC`
    static let ao3CommentDateFormatter = AO3DateParser(
        format: "EEE dd MMM yyyy h:mma zzz",
        timeZone: TimeZone(abbreviation: "UTC")
    )
    
    /// Format: `14 Sep 2026`
    static let ao3BlurbDateFormatter = AO3DateParser(
        format: "dd MMM yyyy",
        timeZone: TimeZone(secondsFromGMT: 0)
    )
    
    /// Format: `Mon, 14 Sep 2026 11:28:59 +0000`
    static let ao3AdminPostDateFormatter = AO3DateParser(
        format: "EEE, dd MMM yyyy HH:mm:ss Z",
        timeZone: nil
    )
}
