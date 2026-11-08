//
//  AtomFeedParser.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 7.11.2026.
//

import Foundation

internal final class AtomFeedParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var incidents: [AO3Incident] = []
    
    private let dateFormatter = ISO8601DateFormatter()
    
    private var isInsideEntry = false
    private var currentElement = ""
    private var currentID = ""
    private var currentTitle = ""
    private var currentContent = ""
    private var currentDateStr = ""
    private var currentLink: String?
    
    private var parseError: Error?
    
    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        self.parser.delegate = self
    }
    
    func parse() throws -> [AO3Incident] {
        parser.parse()
        if let error = parseError ?? parser.parserError {
            throw error
        }
        return incidents
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
            currentID = ""
            currentTitle = ""
            currentContent = ""
            currentDateStr = ""
            currentLink = nil
        } else if isInsideEntry && elementName == "link" {
            if attributeDict["rel"] == "alternate", let href = attributeDict["href"] {
                currentLink = href
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideEntry else { return }
        switch currentElement {
        case "id": currentID += string
        case "title": currentTitle += string
        case "content": currentContent += string
        case "updated": currentDateStr += string
        default: break
        }
    }
    
    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "entry" {
            let trimmedDate = currentDateStr.trimmingCharacters(in: .whitespacesAndNewlines)
            let date = dateFormatter.date(from: trimmedDate) ?? Date()
            
            let incident = AO3Incident(
                id: currentID.trimmingCharacters(in: .whitespacesAndNewlines),
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                link: currentLink
            )
            incidents.append(incident)
            isInsideEntry = false
        }
        currentElement = ""
    }
}
