//
//  SiteAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public struct AO3SiteAPI: Sendable {
    internal let client: AO3Client

    // MARK: FAQ

    public func faqCategories(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3FAQCategory] {
        try await client.fetchCachedItem(
            endpoint: .faq(.index),
            cacheKey: "ao3_faq_categories",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseFAQCategories(html: html)
        }
    }

    public func faqPage(
        id: String,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3FAQPage {
        try await client.fetchCachedItem(
            endpoint: .faq(.show(id: id)),
            cacheKey: "ao3_faq_page_\(id)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseFAQPage(html: html, id: id)
        }
    }

    public func faqPage(
        for category: AO3FAQCategory,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3FAQPage {
        try await faqPage(id: category.id, fallbackStrategy: fallbackStrategy)
    }

    // MARK: Known Issues & Static Pages

    public func knownIssues(
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3KnownIssue] {
        try await client.fetchCachedItem(
            endpoint: .knownIssue(.index),
            cacheKey: "ao3_known_issues",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseKnownIssues(html: html)
        }
    }

    public func staticPage(
        _ page: AO3StaticPage,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3StaticPageContent {
        try await client.fetchCachedItem(
            endpoint: .staticPage(page),
            cacheKey: "ao3_static_page_\(page.rawValue)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseStaticPage(html: html, page: page)
        }
    }

    // MARK: Abuse Reports & Support

    public func submitAbuseReport(_ draft: AO3AbuseReportDraft) async throws {
        try await client.submitAbuseReport(draft)
    }

    public func submitSupportRequest(_ draft: AO3SupportRequestDraft) async throws {
        try await client.submitSupportRequest(draft)
    }
}
