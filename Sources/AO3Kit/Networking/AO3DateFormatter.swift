//
//  AO3DateFormatter.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 13.09.2026.
//

import Foundation
import Synchronization

internal struct AO3DateParser: Sendable, ~Copyable {
    private let lock: Mutex<(formatter: DateFormatter, formats: [String])>
    
    init(formats: [String], timeZone: TimeZone? = TimeZone(secondsFromGMT: 0)) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let timeZone {
            formatter.timeZone = timeZone
        }
        if let first = formats.first {
            formatter.dateFormat = first
        }
        self.lock = Mutex((formatter, formats))
    }
    
    init(format: String, timeZone: TimeZone? = TimeZone(secondsFromGMT: 0)) {
        self.init(formats: [format], timeZone: timeZone)
    }
    
    func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return lock.withLock { state in
            for format in state.formats {
                state.formatter.dateFormat = format
                if let date = state.formatter.date(from: string) {
                    return date
                }
            }
            return nil
        }
    }
}

internal extension DateFormatter {
    /// Format: `2026-09-14`
    static let ao3DateFormatter = AO3DateParser(
        format: "yyyy-MM-dd",
        timeZone: TimeZone(secondsFromGMT: 0)
    )
    
    /// Formats: `Mon 14 Sep 2026 11:28AM UTC` or `Mon 14 Sep 2026 02:28PM +03`
    static let ao3CommentDateFormatter = AO3DateParser(
        formats: [
            "EEE dd MMM yyyy h:mma X",
            "EEE dd MMM yyyy h:mma zzz"
        ],
        timeZone: TimeZone(abbreviation: "UTC")
    )
    
    /// Format: `14 Sep 2026`
    static let ao3BlurbDateFormatter = AO3DateParser(
        format: "dd MMM yyyy",
        timeZone: TimeZone(secondsFromGMT: 0)
    )
    
    /// Formats: `Wed 18 Nov 2026 05:21PM +03`, `Wed 18 Nov 2026 02:21PM UTC`, or RSS `Mon, 14 Sep 2026 11:28:59 +0000`
    static let ao3AdminPostDateFormatter = AO3DateParser(
        formats: [
            "EEE dd MMM yyyy h:mma X",
            "EEE dd MMM yyyy h:mma zzz",
            "EEE, dd MMM yyyy HH:mm:ss Z"
        ],
        timeZone: nil
    )
}
