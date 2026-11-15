//
//  OTWStatusPageParser.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 15.11.2026.
//

import Foundation
import SwiftSoup

internal struct OTWStatusPageSnapshot: Sendable {
    let componentID: String
    let status: AO3OperationalStatus
    var uptimePercentage: Double?
    var uptimeDays: [AO3UptimeDay]
}

internal struct OTWUptimeShowcaseResponse: Decodable, Sendable {
    let components: [String: String]?
}

extension AO3Parser {
    internal static func parseOTWStatusPage(html: String) throws -> OTWStatusPageSnapshot {
        try withDocument(html: html) { doc in
            let ao3Component: Element? = try doc
                .select("div.component-inner-container[data-component-id='w84xs5kg4lp6']")
                .first()
                ?? doc.select("div.component-inner-container").array().first(where: { el in
                    el.firstText("span.name") == "Archive of Our Own"
                })

            guard let component = ao3Component else {
                return OTWStatusPageSnapshot(
                    componentID: "w84xs5kg4lp6",
                    status: .unknown,
                    uptimePercentage: nil,
                    uptimeDays: []
                )
            }

            let componentID = component.firstAttr("[data-uptime-lazy]", "data-uptime-lazy")
                ?? (try? component.attr("data-component-id")).flatMap { $0.isEmpty ? nil : $0 }
                ?? "w84xs5kg4lp6"

            let rawStatusAttr = (try? component.attr("data-component-status"))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
            let statusText = component.firstText("span.component-status")?.lowercased() ?? ""

            let status = mapComponentStatus(attribute: rawStatusAttr, text: statusText, element: component)

            // Parse inline uptime if Statuspage ever disables lazy loading
            let (uptimePercentage, uptimeDays) = extractUptimeMetrics(from: component)

            return OTWStatusPageSnapshot(
                componentID: componentID,
                status: status,
                uptimePercentage: uptimePercentage,
                uptimeDays: uptimeDays
            )
        }
    }

    /// Parses the HTML fragment inside `components[componentID]` from `/uptime_showcase`.
    internal static func parseOTWUptimeShowcase(
        showcaseHTML: String
    ) throws -> (uptimePercentage: Double?, uptimeDays: [AO3UptimeDay]) {
        try withDocument(html: showcaseHTML) { doc in
            extractUptimeMetrics(from: doc)
        }
    }

    private static func extractUptimeMetrics(
        from root: Element
    ) -> (uptimePercentage: Double?, uptimeDays: [AO3UptimeDay]) {
        let rectElements = (try? root.select("svg.availability-time-line-graphic rect.uptime-day").array()) ?? []
        let uptimeDays: [AO3UptimeDay] = rectElements.enumerated().map { fallbackIndex, rect in
            let fillHex = ((try? rect.attr("fill")) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let classAttr = (try? rect.attr("class")) ?? ""
            let dayIndex = extractDayIndex(from: classAttr) ?? fallbackIndex
            let dayStatus = mapRectFillColor(fillHex)

            return AO3UptimeDay(dayIndex: dayIndex, fillHex: fillHex, status: dayStatus)
        }

        let uptimeText = root.firstText(".legend-item-uptime-value span")
        let uptimePercentage = uptimeText.flatMap(Double.init)

        return (uptimePercentage, uptimeDays)
    }

    private static func mapComponentStatus(attribute: String, text: String, element: Element) -> AO3OperationalStatus {
        switch attribute {
        case "operational":
            return .operational
        case "degraded_performance", "partial_outage":
            return .degradedPerformance
        case "major_outage", "under_maintenance":
            return .notOperational
        default:
            break
        }

        if text.contains("degraded") || text.contains("partial") || element.hasClass("status-yellow") || element.hasClass("status-orange") {
            return .degradedPerformance
        }
        if text.contains("operational") || element.hasClass("status-green") {
            return .operational
        }
        if text.contains("outage") || text.contains("maintenance") || element.hasClass("status-red") || element.hasClass("status-blue") {
            return .notOperational
        }
        return .unknown
    }

    private static func mapRectFillColor(_ hex: String) -> AO3OperationalStatus {
        switch hex {
        case "#2fcc66": // Statuspage green
            return .operational
        case "#f1c40f", "#e67e22": // Statuspage yellow / orange
            return .degradedPerformance
        case "#e74c3c", "#3498db": // Statuspage red (outage) / blue (maintenance)
            return .notOperational
        default:
            return .unknown
        }
    }

    private static func extractDayIndex(from classAttribute: String) -> Int? {
        for token in classAttribute.split(separator: " ") {
            if token.hasPrefix("day-"), let index = Int(token.dropFirst(4)) {
                return index
            }
        }
        return nil
    }
}
