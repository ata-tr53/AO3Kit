//
//  AO3PreferencesParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    static func parseUserPreferences(html: String) throws -> AO3UserPreferences {
        try withDocument(html: html) { doc in
            guard let form = try doc.select("form[action*='/preferences/']").first(),
                  let action = try? form.attr("action"),
                  let idPart = action.split(separator: "/").last,
                  let preferenceID = Int(idPart) else {
                throw AO3ClientError.invalidData
            }

            var rawFields: [String: String] = [:]

            for input in try form.select("input[name^='preference[']").array() {
                guard let name = try? input.attr("name"), !name.isEmpty else { continue }
                let type = (try? input.attr("type").lowercased()) ?? "text"
                if type == "checkbox" {
                    rawFields[name] = input.hasAttr("checked") ? "1" : "0"
                } else if type == "hidden" {
                    if rawFields[name] == nil {
                        rawFields[name] = (try? input.attr("value")) ?? ""
                    }
                } else {
                    rawFields[name] = (try? input.attr("value")) ?? ""
                }
            }

            for select in try form.select("select[name^='preference[']").array() {
                guard let name = try? select.attr("name"), !name.isEmpty else { continue }
                if let selected = try select.select("option[selected]").first(),
                   let val = try? selected.attr("value") {
                    rawFields[name] = val
                } else if let first = try select.select("option").first(),
                          let val = try? first.attr("value") {
                    rawFields[name] = val
                }
            }

            func boolVal(_ key: String, default fallback: Bool = false) -> Bool {
                guard let v = rawFields["preference[\(key)]"] else { return fallback }
                return v == "1" || v.lowercased() == "true"
            }

            return AO3UserPreferences(
                preferenceID: preferenceID,
                emailVisible: boolVal("email_visible"),
                dateOfBirthVisible: boolVal("date_of_birth_visible"),
                minimizeSearchEngineVisibility: boolVal("minimize_search_engine_visibility"),
                disableShareLinks: boolVal("disable_share_links"),
                allowCollectionInvitation: boolVal("allow_collection_invitation"),
                allowGifts: boolVal("allow_gifts"),
                adult: boolVal("adult"),
                viewFullWorks: boolVal("view_full_works"),
                hideWarnings: boolVal("hide_warnings"),
                hideFreeform: boolVal("hide_freeform"),
                disableWorkSkins: boolVal("disable_work_skins"),
                hideAllHitCounts: boolVal("hide_all_hit_counts"),
                hideAllKudos: boolVal("hide_all_kudos"),
                hideAllBookmarks: boolVal("hide_all_bookmarks"),
                skinID: rawFields["preference[skin_id]"].flatMap(Int.init),
                timeZone: rawFields["preference[time_zone]"],
                workTitleFormat: rawFields["preference[work_title_format]"],
                commentEmailsOff: boolVal("comment_emails_off"),
                commentInboxOff: boolVal("comment_inbox_off"),
                commentCopyToSelfOff: boolVal("comment_copy_to_self_off"),
                automaticallyApproveCollections: boolVal("automatically_approve_collections"),
                collectionEmailsOff: boolVal("collection_emails_off"),
                collectionInboxOff: boolVal("collection_inbox_off"),
                recipientEmailsOff: boolVal("recipient_emails_off"),
                historyEnabled: boolVal("history_enabled", default: true),
                firstLogin: boolVal("first_login"),
                bannerSeen: boolVal("banner_seen", default: true),
                rawFields: rawFields
            )
        }
    }
}
