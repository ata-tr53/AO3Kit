//
//  WorksGET.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 18.09.2026.
//

import Foundation

public extension AO3Client {
    
    // MARK: Fic API
    
    func fetchFicMetadata(for preview: AO3FicPreview, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3FicMetadata {
        return try await fetchFicMetadata(for: preview.id, fallbackStrategy: fallbackStrategy)
    }
    
    func fetchFicMetadata(for id: Int, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3FicMetadata {
        let endpoint: AO3Endpoint = .work(id: id, route: .main)
        
        guard let url = endpoint.url(bypassAdultBlock: self.bypassAdultBlock) else {
            throw AO3ClientError.invalidURL
        }
        
        let cacheKey = "fic_metadata_\(id)"
        var staleFallbackData: AO3FicMetadata? = nil
        
        if fallbackStrategy != .bypassCache,
           let response: AO3CacheResponse<AO3FicMetadata> = try? await cache.get(forKey: cacheKey) {
            if let data = response.data {
                if response.state == .upToDate || fallbackStrategy == .prioritiseCache {
                    return data
                }
                staleFallbackData = data
            }
        }
        
        do {
            let result = try await taskTracker.track(key: cacheKey) {
                let html = try await self.performRequest(url: url)
                
                let chaptersPageHTML: String?
                if let navUrl = AO3Endpoint.work(id: id, route: .navigate).url() {
                    chaptersPageHTML = try await self.performRequest(url: navUrl)
                } else {
                    chaptersPageHTML = nil
                }
                
                return try await AO3Parser.parseFicMetadata(html: html, chapterHTML: chaptersPageHTML, work: endpoint)
            }
            
            try? await cache.set(result, forKey: cacheKey)
            return result

        } catch {
            if fallbackStrategy == .useCache, let staleData = staleFallbackData {
                return staleData
            }
            throw error
        }
    }

    
    
    //-----------------------------------------------------------------------------------
    
    // MARK: - Chapter Comments API
    
    func fetchChapterCommentsPage(
        for chapterID: Int?,
        in workID: Int? = nil,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3ChapterCommentThread> {
        let endpoint: AO3Endpoint
        
        if let chapterID {
            endpoint = .chapter(id: chapterID, route: .comments)
        } else if let workID {
            endpoint = .work(id: workID, route: .comments)
        } else {
            throw AO3ClientError.invalidURL
        }
        
        return try await self.fetchPaginated(
            url: endpoint.url(bypassAdultBlock: true),
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseComments
        )
        
    }

    
    func fetchAllChapterComments(
        for chapterID: Int?,
        in workID: Int? = nil,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3ChapterCommentThread] {
        let endpoint: AO3Endpoint
        
        if let chapterID {
            endpoint = .chapter(id: chapterID, route: .comments)
        } else if let workID {
            endpoint = .work(id: workID, route: .comments)
        } else {
            throw AO3ClientError.invalidURL
        }
        
        return try await self.fetchAllItems(
            url: endpoint.url(bypassAdultBlock: true),
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseComments
        )
        
    }
    
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
    
    // MARK: Fic Chapters List API
    
    func fetchFicChaptersList(
        for id: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3ChapterLink] {
        
        return try await fetchCachedItem(
            url: AO3Endpoint.work(id: id, route: .navigate).url(bypassAdultBlock: true),
            fallbackStrategy: fallbackStrategy
        ) { html in
            AO3Parser.parseChaptersNavigate(html: html, workID: id)
        }
        
    }
    
    //-----------------------------------------------------------------------------------
    
    //MARK: Chapter Content API
    
    func fetchAllChapters(
        of workID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Chapter] {
        
        return try await fetchCachedItem(
            endpoint: .work(id: workID, route: .fullWork),
            fallbackStrategy: fallbackStrategy
        ) { html in
            try AO3Parser.parseFullWorkChapters(html: html)
        }
        
    }

    
    func fetchChapterContent(for links: [AO3ChapterLink], fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> [AO3Chapter] {
        var chapters: [AO3Chapter] = []
        
        for link in links {
            chapters.append(try await fetchChapterContent(for: link, fallbackStrategy: fallbackStrategy))
        }
        
        return chapters
    }
    
    func fetchChapterContent(for chapterLink: AO3ChapterLink, fallbackStrategy: AO3CacheFallbackStrategy = .useCache) async throws -> AO3Chapter {
        let customKey = "chapter_content_\(chapterLink.id)"
        
        return try await fetchCachedItem(url: chapterLink.url, cacheKey: customKey, fallbackStrategy: fallbackStrategy) { html in
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
