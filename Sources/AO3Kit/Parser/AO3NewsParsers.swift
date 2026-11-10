//
//  AO3NewsParsers.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 16.09.2026.
//

import Foundation
import SwiftSoup

public extension AO3Parser {
    
    static func parseAdminPosts(html: String) throws -> [AO3AdminPost] {
        try parseElements(html: html, selector: "div.news.module.group[role=article]", transform: parseAdminPost)
    }
    
    static func parseAdminPost(html: String) throws -> AO3AdminPost {
        try withDocument(html: html) { doc in
            guard let postElement = try doc.select("div.news.module.group[role=article]").first() else {
                throw AO3ClientError.invalidData
            }
            return try parseAdminPost(from: postElement)
        }
    }
    
    internal static func parseAdminPost(from element: Element) throws -> AO3AdminPost {
        guard let href = element.firstAttr("div.header h3.heading a", "href"),
              let idString = href.components(separatedBy: "/").last,
              let id = Int(idString),
              let userstuff = try element.select("div.userstuff").first() else {
            throw AO3ClientError.invalidData
        }
        
        let title = element.firstText("div.header h3.heading a") ?? "Unknown Title"
        let publishDate = DateFormatter.ao3AdminPostDateFormatter.date(from: element.firstText("dd.published") ?? "") ?? Date()
        let tags = element.texts("dd.tags a.tag")
        
        var displayImage: AO3Image? = nil
        if let firstImg = try userstuff.select("img").first(),
           let parsedImg = parseImage(from: firstImg) {
            displayImage = parsedImg
            if let parent = firstImg.parent(), parent.tagName() == "p", parent.children().count == 1 {
                try parent.remove()
            } else {
                try firstImg.remove()
            }
        }
        
        return AO3AdminPost(
            id: id,
            title: title,
            publishDate: publishDate,
            tags: tags,
            displayImage: displayImage,
            contentHTML: try userstuff.html()
        )
    }
    
}
