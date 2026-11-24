//
//  AO3InvitationParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    static func parseInviteQueueStatus(html: String, email: String) throws -> AO3InviteQueueStatus {
        try withDocument(html: html) { doc in
            let container = try doc.select("div#invite-status, div.invite.status, div#main").first()
            let message = (try? container?.select("p").array().compactMap { try? $0.text() }.joined(separator: " "))
                ?? (try? container?.text()) ?? ""
            let cleanMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

            var position: Int? = nil
            var totalInQueue: Int? = nil
            var estimatedDate: String? = nil

            if let posRegex = try? NSRegularExpression(pattern: #"#([\d,]+)\s+of\s+([\d,]+)"#),
               let match = posRegex.firstMatch(in: cleanMessage, range: NSRange(cleanMessage.startIndex..., in: cleanMessage)) {
                if let r1 = Range(match.range(at: 1), in: cleanMessage) {
                    position = parseInt(String(cleanMessage[r1]))
                }
                if let r2 = Range(match.range(at: 2), in: cleanMessage) {
                    totalInQueue = parseInt(String(cleanMessage[r2]))
                }
            }

            if let dateRegex = try? NSRegularExpression(pattern: #"around\s+([A-Za-z]+\s+\d{1,2},\s+\d{4})"#),
               let match = dateRegex.firstMatch(in: cleanMessage, range: NSRange(cleanMessage.startIndex..., in: cleanMessage)),
               let r = Range(match.range(at: 1), in: cleanMessage) {
                estimatedDate = String(cleanMessage[r])
            }

            return AO3InviteQueueStatus(
                email: email,
                position: position,
                totalInQueue: totalInQueue,
                estimatedDate: estimatedDate,
                message: cleanMessage
            )
        }
    }

    static func parseUserInvitations(html: String) throws -> [AO3Invitation] {
        try parseElements(html: html, selector: "table tbody tr") { row in
            let cells = (try? row.select("td, th").array()) ?? []
            guard !cells.isEmpty else { return nil }

            let tokenLink = try? row.select("a[href*='/signup/'], a[href*='/invitations/']").first()
            let token: String
            if let href = try? tokenLink?.attr("href"),
               let last = href.split(separator: "/").last,
               !last.isEmpty {
                token = String(last)
            } else if let text = try? cells[0].text().trimmingCharacters(in: .whitespacesAndNewlines),
                      !text.isEmpty {
                token = text
            } else {
                return nil
            }

            let inviteeEmail = cells.count > 1
                ? (try? cells[1].text().trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
                : nil
            let redeemedBy = (try? row.select("a[href^='/users/']").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines))
            let sentAt = cells.count > 2
                ? (try? cells[2].text().trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
                : nil
            let isUsed = redeemedBy != nil || (try? row.text().localizedCaseInsensitiveContains("redeemed")) == true

            return AO3Invitation(
                token: token,
                inviteeEmail: inviteeEmail,
                redeemedBy: redeemedBy,
                sentAt: sentAt,
                isUsed: isUsed
            )
        }
    }
}
