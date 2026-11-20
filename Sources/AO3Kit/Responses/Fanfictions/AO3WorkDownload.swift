//
//  AO3WorkDownload.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public enum AO3DownloadFormat: String, CaseIterable, Sendable, Codable, Hashable {
    case azw3
    case epub
    case mobi
    case pdf
    case html

    public var fileExtension: String { rawValue }

    public var displayName: String {
        rawValue.uppercased()
    }

    public var mimeType: String {
        switch self {
        case .azw3: return "application/vnd.amazon.ebook"
        case .epub: return "application/epub+zip"
        case .mobi: return "application/x-mobipocket-ebook"
        case .pdf: return "application/pdf"
        case .html: return "text/html"
        }
    }
}

public struct AO3DownloadLink: Identifiable, Sendable, Codable, Hashable, AO3Response {
    public var id: String { "\(workID)_\(format.rawValue)" }
    public var workID: Int
    public var title: String
    public var format: AO3DownloadFormat
    public var url: URL

    public static var responseType: ResponseType { .download }

    public init(workID: Int, title: String, format: AO3DownloadFormat, url: URL) {
        self.workID = workID
        self.title = title
        self.format = format
        self.url = url
    }
}

public struct AO3WorkDownload: Sendable, Hashable {
    public var workID: Int
    public var format: AO3DownloadFormat
    public var suggestedFilename: String
    public var data: Data

    public init(workID: Int, format: AO3DownloadFormat, suggestedFilename: String, data: Data) {
        self.workID = workID
        self.format = format
        self.suggestedFilename = suggestedFilename
        self.data = data
    }
}
