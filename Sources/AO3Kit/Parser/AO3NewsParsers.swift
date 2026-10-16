//
//  AO3NewsParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    // MARK: - Admin Posts Parsers
    
    static func parseAdminPosts(html: String) throws -> [AO3AdminPost] {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer { doc.empty() }
            
            let postElements = try doc.select("div.news.module.group[role=article]").array()
            
            return postElements.compactMap { element in
                do {
                    return try parseAdminPost(from: element)
                } catch {
                    print("⚠️ Failed to parse an admin post: \(error)")
                    return nil
                }
            }
        }
    }
    
    static func parseAdminPost(html: String) throws -> AO3AdminPost {
        return try autoreleasepool {
            let doc = try SwiftSoup.parse(html)
            
            defer { doc.empty() }
            
            guard let postElement = try doc.select("div.news.module.group[role=article]").first() else {
                throw AO3ClientError.invalidData
            }
            
            return try parseAdminPost(from: postElement)
        }
    }
    
    internal static func parseAdminPost(from element: Element) throws -> AO3AdminPost {
        // ID and Title
        let titleLink = try element.select("div.header h3.heading a").first()
        let title = try titleLink?.text() ?? "Unknown Title"
        
        let href = try titleLink?.attr("href") ?? ""
        let idString = href.components(separatedBy: "/").last ?? ""
        guard let id = Int(idString) else {
            throw AO3ClientError.invalidData
        }
        
        // Publish Date
        let dateText = try element.select("dd.published").first()?.text() ?? ""
        let publishDate = DateFormatter.ao3AdminPostDateFormatter.date(from: dateText) ?? Date()
        
        // Tags
        let tags = try element.select("dd.tags a.tag").array().map { try $0.text() }
        
        // Content & Display Image
        guard let userstuff = try element.select("div.userstuff").first() else {
            throw AO3ClientError.invalidData
        }
        
        var displayImage: AO3Image? = nil
        
        if let firstImg = try userstuff.select("img").first() {
            let src = try firstImg.attr("src")
            let alt = try firstImg.attr("alt")
            
            if !src.isEmpty {
                let fullURL = src.hasPrefix("http") ? src : "https://archiveofourown.org\(src)"
                displayImage = AO3Image(
                    description: alt.isEmpty ? nil : alt,
                    source: fullURL
                )
                
                if let parent = firstImg.parent(), parent.tagName() == "p", parent.children().count == 1 {
                    try parent.remove()
                } else {
                    try firstImg.remove()
                }
            }
        }
        
        let contentHTML = try userstuff.html()
        
        return AO3AdminPost(
            id: id,
            title: title,
            publishDate: publishDate,
            tags: tags,
            displayImage: displayImage,
            contentHTML: contentHTML
        )
    }
}
