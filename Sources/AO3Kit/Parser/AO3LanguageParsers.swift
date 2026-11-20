//
//  AO3LanguageParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    static func parseLanguages(html: String) throws -> [AO3Language] {
        try withDocument(html: html) { doc in
            let dtElements = try doc.select("dl.language.index dt").array()
            var results: [AO3Language] = []

            for dt in dtElements {
                guard let link = try dt.select("a[href^='/languages/']").first(),
                      let href = try? link.attr("href"),
                      let name = try? link.text().trimmingCharacters(in: .whitespacesAndNewlines),
                      !name.isEmpty else {
                    continue
                }

                let parts = href.split(separator: "/").map(String.init)
                guard let langIdx = parts.firstIndex(of: "languages"), langIdx + 1 < parts.count else {
                    continue
                }
                let langID = parts[langIdx + 1]

                var workCount = 0
                if let dd = try? dt.nextElementSibling(), dd.tagName().lowercased() == "dd" {
                    let ddText = (try? dd.text()) ?? ""
                    let digits = ddText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    workCount = Int(digits) ?? 0
                }

                results.append(AO3Language(id: langID, name: name, workCount: workCount))
            }

            return results
        }
    }
}
