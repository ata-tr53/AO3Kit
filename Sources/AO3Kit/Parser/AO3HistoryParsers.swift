//
//  AO3HistoryParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 6.10.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - Reading History Parser
    
    static func parseHistoryFicPreviews(html: String) throws -> [AO3HistoryFicPreview] {
        try parseElements(html: html, selector: "li.reading.work.blurb", transform: parseHistoryFicPreview)
    }
    
    internal static func parseHistoryFicPreview(from element: Element) throws -> AO3HistoryFicPreview {
        let preview = try parseFicPreview(from: element)
        guard let userModule = try element.select("div.user.module.group").first(),
              let deleteActionString = userModule.firstAttr("input[name=reading]", "value"),
              let deleteActionID = Int(deleteActionString) else {
            throw AO3ClientError.invalidData
        }
        
        let viewedHeading = userModule.firstText("h4.viewed.heading") ?? ""
        let datePart = viewedHeading.components(separatedBy: "(").first?
            .replacingOccurrences(of: "Last visited:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let lastVisitTime = DateFormatter.ao3BlurbDateFormatter.date(from: datePart) ?? Date()
        let newUpdateAvailable = viewedHeading.contains("Update") || viewedHeading.contains("Minor edit")
        let isMarkedForLater = viewedHeading.contains("Marked for Later")
        
        var visitCount = 1
        if let match = viewedHeading.range(of: #"Visited \d+ time"#, options: .regularExpression) {
            let numberString = viewedHeading[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            visitCount = Int(numberString) ?? 1
        }
        
        return AO3HistoryFicPreview(
            preview: preview,
            lastVisitTime: lastVisitTime,
            newUpdateAvailable: newUpdateAvailable,
            visitCount: visitCount,
            isMarkedForLater: isMarkedForLater,
            deleteActionID: deleteActionID
        )
    }
}
