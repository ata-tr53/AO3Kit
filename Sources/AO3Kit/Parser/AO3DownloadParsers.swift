//
//  AO3DownloadParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    static func parseDownloadLinks(html: String, workID: Int) throws -> [AO3DownloadLink] {
        try withDocument(html: html) { doc in
            let links = try doc.select("li.download ul.expandable.secondary a[href^='/downloads/'], a[href^='/downloads/\(workID)/']").array()
            var seenFormats: Set<AO3DownloadFormat> = []
            var results: [AO3DownloadLink] = []

            for element in links {
                guard let href = try? element.attr("href"), !href.isEmpty else { continue }
                let fullURLString = href.hasPrefix("http") ? href : "https://archiveofourown.org\(href)"
                guard let url = URL(string: fullURLString) else { continue }

                if case .download(let parsedWorkID, let title, let formatString) = AO3Client.dissect(url: url),
                   let format = AO3DownloadFormat(rawValue: formatString.lowercased()),
                   seenFormats.insert(format).inserted {
                    results.append(
                        AO3DownloadLink(
                            workID: parsedWorkID,
                            title: title,
                            format: format,
                            url: url
                        )
                    )
                }
            }

            return results
        }
    }
}
