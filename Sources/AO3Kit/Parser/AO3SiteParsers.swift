//
//  AO3SiteParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {

    static func parseFAQCategories(html: String) throws -> [AO3FAQCategory] {
        try parseElements(html: html, selector: "div.faq ul.categories a[href^='/faq/'], div#main ul a[href^='/faq/']") { link in
            guard let href = try? link.attr("href"),
                  let slug = href.split(separator: "/").last.map(String.init),
                  !slug.isEmpty,
                  let title = try? link.text().trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty else {
                return nil
            }
            return AO3FAQCategory(id: slug, title: title)
        }
    }

    static func parseFAQPage(html: String, id: String) throws -> AO3FAQPage {
        try withDocument(html: html) { doc in
            let title = doc.firstText("div#main h2.heading, h2.heading") ?? id
            let contentHTML = (try? doc.select("div.userstuff, div.faq").first()?.html()) ?? ""

            var questions: [AO3FAQQuestion] = []
            let headings = (try? doc.select("div.userstuff h3[id], div.faq h3[id]").array()) ?? []
            for heading in headings {
                let qID = heading.id()
                let qText = (try? heading.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                var answerParts: [String] = []
                var sibling = try? heading.nextElementSibling()
                while let current = sibling, current.tagName() != "h3" {
                    if let outer = try? current.outerHtml() {
                        answerParts.append(outer)
                    }
                    sibling = try? current.nextElementSibling()
                }
                if !qText.isEmpty {
                    questions.append(AO3FAQQuestion(
                        id: qID.isEmpty ? qText : qID,
                        question: qText,
                        answerHTML: answerParts.joined(separator: "\n")
                    ))
                }
            }

            return AO3FAQPage(id: id, title: title, contentHTML: contentHTML, questions: questions)
        }
    }

    static func parseKnownIssues(html: String) throws -> [AO3KnownIssue] {
        try parseElements(html: html, selector: "div.known.issues.module, div.admin.module, div#main div.userstuff") { element in
            let headingLink = try? element.select("h3.heading a[href^='/known_issues/'], h2.heading a[href^='/known_issues/']").first()
            let href = (try? headingLink?.attr("href")) ?? ""
            let id = href.split(separator: "/").last.flatMap { Int($0) } ?? 0
            let title = (try? headingLink?.text().trimmingCharacters(in: .whitespacesAndNewlines))
                ?? element.firstText("h3.heading, h2.heading") ?? "Known Issues"
            let date = element.firstText("p.datetime")
            let contentHTML = (try? element.select("div.userstuff").first()?.html())
                ?? (try? element.html()) ?? ""

            return AO3KnownIssue(id: id, title: title, date: date, contentHTML: contentHTML)
        }
    }

    static func parseStaticPage(html: String, page: AO3StaticPage) throws -> AO3StaticPageContent {
        try withDocument(html: html) { doc in
            let title = doc.firstText("div#main h2.heading, h2.heading") ?? page.rawValue
            let contentHTML = (try? doc.select("div#main div.userstuff, div#main").first()?.html()) ?? ""
            return AO3StaticPageContent(
                pageSlug: page.rawValue,
                title: title,
                contentHTML: contentHTML,
                url: AO3Endpoint.staticPage(page).url()
            )
        }
    }
}
