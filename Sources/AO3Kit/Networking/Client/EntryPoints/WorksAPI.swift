//
//  WorksAPI.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public struct AO3WorksAPI: Sendable {
    internal let client: AO3Client
    
    // MARK: Metadata
    
    public func metadata(
        for workID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3FicMetadata {
        try await client.fetchFicMetadata(for: workID, fallbackStrategy: fallbackStrategy)
    }
    
    public func metadata<Fic: AO3FicModel>(
        for fic: Fic,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3FicMetadata {
        try await client.fetchFicMetadata(for: fic.id, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Chapters List
    
    public func chaptersList(
        for workID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3ChapterLink] {
        try await client.fetchFicChaptersList(for: workID, fallbackStrategy: fallbackStrategy)
    }
    
    public func chaptersList<Fic: AO3FicModel>(
        for fic: Fic,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3ChapterLink] {
        try await client.fetchFicChaptersList(for: fic.id, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: All Chapters
    
    public func allChapters(
        for workID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Chapter] {
        try await client.fetchAllChapters(for: workID, fallbackStrategy: fallbackStrategy)
    }
    
    public func allChapters<Fic: AO3FicModel>(
        for fic: Fic,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Chapter] {
        try await client.fetchAllChapters(for: fic.id, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Chapter Content
    
    public func chapterContent(
        for chapterLink: AO3ChapterLink,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3Chapter {
        try await client.fetchChapterContent(for: chapterLink, fallbackStrategy: fallbackStrategy)
    }
    
    public func chapterContent(
        for links: [AO3ChapterLink],
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3Chapter] {
        try await client.fetchChapterContent(for: links, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Paginated Work Lists (User Works, Gifts, Collections, Tags)
    
    public func page(
        from source: AO3WorkSource,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3FicPreview> {
        try await client.fetchPaginated(
            endpoint: source.endpoint,
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
    }
    
    public func all(
        from source: AO3WorkSource,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3FicPreview] {
        try await client.fetchAllItems(
            endpoint: source.endpoint,
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseFicPreviews
        )
    }
    
    // MARK: Comments
    
    public func commentsPage(
        for target: AO3CommentTarget,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3ChapterCommentThread> {
        try await client.fetchPaginated(
            endpoint: target.endpoint,
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseComments
        )
    }
    
    public func allComments(
        for target: AO3CommentTarget,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3ChapterCommentThread] {
        try await client.fetchAllItems(
            endpoint: target.endpoint,
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseComments
        )
    }
    
    public func commentThread(
        for commentID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3ChapterCommentThread {
        try await client.fetchCommentThread(for: commentID, fallbackStrategy: fallbackStrategy)
    }
    
    // MARK: Mutations
    
    @discardableResult
    public func leaveKudos(for workID: Int) async throws -> Bool {
        try await client.leaveKudos(for: workID)
    }
    
    @discardableResult
    public func leaveKudos<Fic: AO3FicModel>(for work: Fic) async throws -> Bool {
        try await client.leaveKudos(for: work.id)
    }
    
    public func postComment(
        content: String,
        pseudName: String,
        chapterID: Int,
        replyToCommentID: Int? = nil
    ) async throws {
        try await client.postComment(
            content: content,
            pseudName: pseudName,
            chapterID: chapterID,
            replyToCommentID: replyToCommentID
        )
    }
    
    public func postComment(
        content: String,
        pseudName: String,
        chapter link: AO3ChapterLink,
        replyToCommentID: Int? = nil
    ) async throws {
        try await client.postComment(
            content: content,
            pseudName: pseudName,
            chapterID: link.id,
            replyToCommentID: replyToCommentID
        )
    }
    
    public func toggleMarkForLater(workID: Int, isMarkingForLater: Bool) async throws {
        try await client.toggleMarkForLater(workID: workID, isMarkingForLater: isMarkingForLater)
    }
    
    public func toggleMarkForLater<Fic: AO3FicModel>(work: Fic, isMarkingForLater: Bool) async throws {
        try await client.toggleMarkForLater(workID: work.id, isMarkingForLater: isMarkingForLater)
    }

    // MARK: Downloads

    public func downloadLinks(
        for workID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3DownloadLink] {
        try await client.fetchDownloadLinks(for: workID, fallbackStrategy: fallbackStrategy)
    }

    public func downloadLinks<Fic: AO3FicModel>(
        for fic: Fic,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> [AO3DownloadLink] {
        try await client.fetchDownloadLinks(for: fic.id, fallbackStrategy: fallbackStrategy)
    }

    public func download(
        workID: Int,
        format: AO3DownloadFormat,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3WorkDownload {
        try await client.downloadWork(workID: workID, format: format, fallbackStrategy: fallbackStrategy)
    }

    public func download<Fic: AO3FicModel>(
        _ fic: Fic,
        format: AO3DownloadFormat,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3WorkDownload {
        try await client.downloadWork(workID: fic.id, format: format, fallbackStrategy: fallbackStrategy)
    }

    public func download(from link: AO3DownloadLink) async throws -> AO3WorkDownload {
        try await client.downloadWork(from: link)
    }

    // MARK: Kudos List

    public func kudos(
        for workID: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3WorkKudos {
        try await client.fetchWorkKudos(for: workID, fallbackStrategy: fallbackStrategy)
    }

    public func kudos<Fic: AO3FicModel>(
        for fic: Fic,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3WorkKudos {
        try await client.fetchWorkKudos(for: fic.id, fallbackStrategy: fallbackStrategy)
    }

    // MARK: Comment Edit, Delete & Moderation

    public func commentsPage<Target: AO3Commentable>(
        for target: Target,
        page: Int = 1,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache
    ) async throws -> AO3PaginatedResult<AO3ChapterCommentThread> {
        try await client.fetchPaginated(
            endpoint: target.commentsEndpoint,
            page: page,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseComments
        )
    }

    public func allComments<Target: AO3Commentable>(
        for target: Target,
        maxPages: Int? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        progressHandler: (@Sendable (_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> [AO3ChapterCommentThread] {
        try await client.fetchAllItems(
            endpoint: target.commentsEndpoint,
            maxPages: maxPages,
            progressHandler: progressHandler,
            fallbackStrategy: fallbackStrategy,
            parser: AO3Parser.parseComments
        )
    }

    public func postComment<Target: AO3Commentable>(
        on target: Target,
        content: String,
        pseudName: String
    ) async throws {
        try await client.postComment(on: target, content: content, pseudName: pseudName)
    }

    public func editComment(id commentID: Int, content: String) async throws {
        try await client.editComment(id: commentID, content: content)
    }

    public func editComment<Comment: AO3ModerableComment>(_ comment: Comment, content: String) async throws {
        try await client.editComment(id: comment.commentID, content: content)
    }

    public func deleteComment(id commentID: Int) async throws {
        try await client.deleteComment(id: commentID)
    }

    public func deleteComment<Comment: AO3ModerableComment>(_ comment: Comment) async throws {
        try await client.deleteComment(id: comment.commentID)
    }

    public func moderateComment(id commentID: Int, action: AO3CommentModerationAction) async throws {
        try await client.moderateComment(id: commentID, action: action)
    }

    public func moderateComment<Comment: AO3ModerableComment>(_ comment: Comment, action: AO3CommentModerationAction) async throws {
        try await client.moderateComment(id: comment.commentID, action: action)
    }

    public func reviewAllComments(for workID: Int) async throws {
        try await client.reviewAllComments(forWorkID: workID)
    }

    public func reviewAllComments<Fic: AO3FicModel>(for fic: Fic) async throws {
        try await client.reviewAllComments(forWorkID: fic.id)
    }

    // MARK: Hit Count

    public func recordHitCount(for workID: Int) async throws {
        try await client.recordHitCount(for: workID)
    }

    public func recordHitCount<Fic: AO3FicModel>(for fic: Fic) async throws {
        try await client.recordHitCount(for: fic.id)
    }
}
