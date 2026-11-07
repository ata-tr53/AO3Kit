//
//  AtomFeedParser.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 7.11.2026.
//

import Foundation

internal class AtomFeedParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var incidents: [AO3Incident] = []
    
    private var currentElement = ""
    private var currentTitle = ""
    private var currentContent = ""
    private var currentDateStr = ""
    private var currentLink: String? = nil
    
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
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "entry" {
            currentTitle = ""
            currentContent = ""
            currentDateStr = ""
            currentLink = nil
        } else if elementName == "link" {
            if let href = attributeDict["href"] {
                currentLink = href
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "content": currentContent += string
        case "updated": currentDateStr += string
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "entry" {
            // OTW Atom feed uses ISO8601 formatting for dates
            let formatter = ISO8601DateFormatter()
            let date = formatter.date(from: currentDateStr.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Date()
            
            let incident = AO3Incident(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                link: currentLink
            )
            incidents.append(incident)
        }
        currentElement = ""
    }
}
