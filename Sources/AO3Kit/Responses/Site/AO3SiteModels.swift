//
//  AO3SiteModels.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public struct AO3FAQCategory: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: String
    public let title: String

    public var url: URL? {
        AO3Endpoint.faq(.show(id: id)).url()
    }

    public static var responseType: ResponseType { .faq }

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct AO3FAQQuestion: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let question: String
    public let answerHTML: String

    public init(id: String, question: String, answerHTML: String) {
        self.id = id
        self.question = question
        self.answerHTML = answerHTML
    }
}

public struct AO3FAQPage: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: String
    public let title: String
    public let contentHTML: String
    public let questions: [AO3FAQQuestion]

    public var url: URL? {
        AO3Endpoint.faq(.show(id: id)).url()
    }

    public static var responseType: ResponseType { .faq }

    public init(id: String, title: String, contentHTML: String, questions: [AO3FAQQuestion] = []) {
        self.id = id
        self.title = title
        self.contentHTML = contentHTML
        self.questions = questions
    }
}

public struct AO3KnownIssue: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public let id: Int
    public let title: String
    public let date: String?
    public let contentHTML: String

    public var url: URL? {
        AO3Endpoint.knownIssue(.show(id: id)).url()
    }

    public static var responseType: ResponseType { .knownIssue }

    public init(id: Int, title: String, date: String? = nil, contentHTML: String) {
        self.id = id
        self.title = title
        self.date = date
        self.contentHTML = contentHTML
    }
}

public struct AO3StaticPageContent: Sendable, Codable, Hashable, AO3Response {
    public let pageSlug: String
    public let title: String
    public let contentHTML: String
    public let url: URL?

    public static var responseType: ResponseType { .staticPage }

    public init(pageSlug: String, title: String, contentHTML: String, url: URL? = nil) {
        self.pageSlug = pageSlug
        self.title = title
        self.contentHTML = contentHTML
        self.url = url
    }
}

public struct AO3AbuseReportDraft: Sendable, Codable, Hashable {
    /// URL of the AO3 page being reported (`abuse_report[url]`).
    public var reportedURL: URL
    public var summary: String
    public var comment: String
    public var email: String
    public var username: String?
    public var language: String

    public init(
        reportedURL: URL,
        summary: String,
        comment: String,
        email: String,
        username: String? = nil,
        language: String = "English"
    ) {
        self.reportedURL = reportedURL
        self.summary = summary
        self.comment = comment
        self.email = email
        self.username = username
        self.language = language
    }
}

public struct AO3SupportRequestDraft: Sendable, Codable, Hashable {
    public var email: String
    public var username: String?
    public var summary: String
    public var comment: String
    public var category: String
    public var language: String

    public init(
        email: String,
        summary: String,
        comment: String,
        username: String? = nil,
        category: String = "Bug Report",
        language: String = "English"
    ) {
        self.email = email
        self.username = username
        self.summary = summary
        self.comment = comment
        self.category = category
        self.language = language
    }
}
