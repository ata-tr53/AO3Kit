//
//  WorksGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

internal extension AO3Client {
    
    // MARK: - Fic API
    
    func fetchFicMetadata(
        for id: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3FicMetadata {
        let mainEndpoint: AO3Endpoint = .work(id: id, route: .main)
        let navEndpoint: AO3Endpoint = .work(id: id, route: .navigate)
        
        return try await fetchCachedItem(
            endpoint: mainEndpoint,
            cacheKey: "fic_metadata_\(id)",
            fallbackStrategy: fallbackStrategy
        ) { html in
            let chaptersPageHTML: String?
            if let navURL = navEndpoint.url(bypassAdultBlock: self.bypassAdultBlock) {
                chaptersPageHTML = try await self.performRequest(url: navURL)
            } else {
                chaptersPageHTML = nil
            }
            
            return try await AO3Parser.parseFicMetadata(
                html: html,
                chapterHTML: chaptersPageHTML,
                work: mainEndpoint
            )
        }
    }
    
    //-----------------------------------------------------------------------------------
    
    // MARK: - Single Comment Thread API
    
    func fetchCommentThread(
        for commentID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3ChapterCommentThread {
        return try await fetchCachedItem(
            endpoint: .commentThread(id: commentID),
            fallbackStrategy: fallbackStrategy
        ) { html in
            let threads = try AO3Parser.parseComments(html: html)
            guard let result = threads.first else {
                throw AO3ClientError.invalidData
            }
            return result
        }
    }
    
    //-----------------------------------------------------------------------------------
    
    // MARK: - Fic Chapters List API
    
    func fetchFicChaptersList(
        for id: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3ChapterLink] {
        return try await fetchCachedItem(
            endpoint: .work(id: id, route: .navigate),
            fallbackStrategy: fallbackStrategy
        ) { html in
            AO3Parser.parseChaptersNavigate(html: html, workID: id)
        }
    }
    
    //-----------------------------------------------------------------------------------
    
    // MARK: - Chapter Content API
    
    func fetchAllChapters(
        for workID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Chapter] {
        return try await fetchCachedItem(
            endpoint: .work(id: workID, route: .fullWork),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseFullWorkChapters(html: html)
        }
    }
    
    func fetchChapterContent(
        for links: [AO3ChapterLink],
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Chapter] {
        var chapters: [AO3Chapter] = []
        for link in links {
            chapters.append(try await fetchChapterContent(for: link, fallbackStrategy: fallbackStrategy))
        }
        return chapters
    }
    
    func fetchChapterContent(
        for chapterLink: AO3ChapterLink,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3Chapter {
        let customKey = "chapter_content_\(chapterLink.id)"
        
        return try await fetchCachedItem(
            endpoint: .chapter(id: chapterLink.id, route: .main),
            cacheKey: customKey,
            fallbackStrategy: fallbackStrategy
        ) { html in
            try await AO3Parser.parseChapter(html: html, chapterLink: chapterLink)
        }
    }
    
    //-----------------------------------------------------------------------------------
    
    // MARK: - Work Bookmarks API
    
    func fetchWorkBookmarksPage(
        for workID: Int,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3BookmarkPreview> {
        return try await self.fetchPaginated(
            endpoint: .work(id: workID, route: .bookmarks),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseWorkBookmarks
        )
    }
    
    func fetchAllWorkBookmarks(
        for workID: Int,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3BookmarkPreview] {
        return try await self.fetchAllItems(
            endpoint: .work(id: workID, route: .bookmarks),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseWorkBookmarks
        )
    }
}
