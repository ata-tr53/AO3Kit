//
//  AO3TagFeedParser.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 24.11.2026.
//

import Foundation

internal final class AO3TagFeedParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private let dateFormatter = ISO8601DateFormatter()

    private var feedID = ""
    private var feedTitle = ""
    private var feedUpdatedStr = ""
    private var feedSelfURL: URL?
    private var entries: [AO3TagFeedEntry] = []

    private var isInsideEntry = false
    private var isInsideAuthor = false
    private var currentElement = ""

    private var entryID = ""
    private var entryTitle = ""
    private var entryAuthors: [String] = []
    private var currentAuthorName = ""
    private var entryPublishedStr = ""
    private var entryUpdatedStr = ""
    private var entryLink: URL?
    private var entrySummary = ""

    private var parseError: Error?

    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        self.parser.delegate = self
    }

    func parse() throws -> AO3TagFeed {
        parser.parse()
        if let error = parseError ?? parser.parserError {
            throw error
        }
        return AO3TagFeed(
            id: feedID.trimmingCharacters(in: .whitespacesAndNewlines),
            title: feedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            updated: dateFormatter.date(from: feedUpdatedStr.trimmingCharacters(in: .whitespacesAndNewlines)),
            feedURL: feedSelfURL,
            entries: entries
        )
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName

        if elementName == "entry" {
            isInsideEntry = true
            entryID = ""
            entryTitle = ""
            entryAuthors = []
            entryPublishedStr = ""
            entryUpdatedStr = ""
            entryLink = nil
            entrySummary = ""
        } else if isInsideEntry && elementName == "author" {
            isInsideAuthor = true
            currentAuthorName = ""
        } else if elementName == "link", let href = attributeDict["href"], let url = URL(string: href) {
            if isInsideEntry, attributeDict["rel"] == "alternate" {
                entryLink = url
            } else if !isInsideEntry, attributeDict["rel"] == "self" {
                feedSelfURL = url
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !isInsideEntry {
            switch currentElement {
            case "id": feedID += string
            case "title": feedTitle += string
            case "updated": feedUpdatedStr += string
            default: break
            }
            return
        }

        if isInsideAuthor && currentElement == "name" {
            currentAuthorName += string
            return
        }

        switch currentElement {
        case "id": entryID += string
        case "title": entryTitle += string
        case "published": entryPublishedStr += string
        case "updated": entryUpdatedStr += string
        case "summary", "content": entrySummary += string
        default: break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if isInsideEntry && elementName == "author" {
            let trimmed = currentAuthorName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { entryAuthors.append(trimmed) }
            isInsideAuthor = false
        } else if elementName == "entry" {
            let cleanID = entryID.trimmingCharacters(in: .whitespacesAndNewlines)
            let workID = extractWorkID(from: entryLink, fallbackAtomID: cleanID)

            entries.append(AO3TagFeedEntry(
                id: cleanID,
                workID: workID,
                title: entryTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                authors: entryAuthors,
                published: dateFormatter.date(from: entryPublishedStr.trimmingCharacters(in: .whitespacesAndNewlines)),
                updated: dateFormatter.date(from: entryUpdatedStr.trimmingCharacters(in: .whitespacesAndNewlines)),
                url: entryLink,
                summaryHTML: entrySummary.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            isInsideEntry = false
        }
        currentElement = ""
    }

    private func extractWorkID(from url: URL?, fallbackAtomID: String) -> Int? {
        if let url, case .work(let id, _) = AO3Client.dissect(url: url) {
            return id
        }
        if let suffix = fallbackAtomID.split(separator: "/").last {
            return Int(suffix)
        }
        return nil
    }
}
