//
//  AO3Client.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 2.08.2026.
//

import Foundation

@Observable
public final class AO3Client: Sendable {
    
    internal let session: URLSession
    internal let userAgent: String
    
    public let cache: AO3Cache
    internal let taskTracker = AO3TaskTracker()
    
    internal let bypassAdultBlock: Bool
    public let cullRequestsOnOutage: Bool
    
    public init(
        session: URLSession = .shared,
        userAgent: String = "AO3Kit/1.0 (Compatible; iOS/macOS)",
        bypassAdultBlock: Bool = true,
        cache: AO3Cache = AO3Cache(
            storageStrategy: .memoryOnly,
            memoryCountLimit: 20
        ),
        cullRequestsOnOutage: Bool = true
    ) {
        self.session = session
        self.userAgent = userAgent
        self.bypassAdultBlock = bypassAdultBlock
        self.cache = cache
        self.cullRequestsOnOutage = cullRequestsOnOutage
        
        if bypassAdultBlock {
            if let adultCookie = HTTPCookie(properties: [
                .domain: "archiveofourown.org",
                .path: "/",
                .name: "view_adult",
                .value: "true",
                .secure: "TRUE",
                .expires: Date().addingTimeInterval(60 * 60 * 24 * 365) // 1 year
            ]) {
                self.session.configuration.httpCookieStorage?.setCookie(adultCookie)
            }
        }
    }
    
    static internal let validHosts: Set<String> = [
        "archiveofourown.org",
        "archiveofourown.com",
        "archiveofourown.net",
        "archiveofourown.gay",
        "ao3.org",
        "archive.transformativeworks.org",
        "insecure.archiveofourown.org"
    ]
    
    //-----------------------------------------------------------------------------------
    
    // MARK: URL Recognition
    public static func isAO3(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return validHosts.contains { url.absoluteString.contains($0) }
        }
        
        if validHosts.contains(host) {
            return true
        }
        
        return validHosts.contains { host.hasSuffix(".\($0)") }
    }
    
    public static func dissect(url: URL) -> AO3Endpoint {
        guard let host = url.host, host.contains("archiveofourown.org") else { return .unknown }
        
        let pathParts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard !pathParts.isEmpty else { return .home }
        
        let root = pathParts[0]
        let remainder = Array(pathParts.dropFirst(1))
        
        switch root {
        case "works":
            if remainder.first == "search" { return .worksSearch }
            
            guard let idStr = remainder.first, let id = Int(idStr) else { return .unknown }
            let workRemainder = Array(remainder.dropFirst(1))
            return .work(id: id, route: AO3WorkRoute.dissect(remainder: workRemainder))
            
        case "tags":
            if remainder.first == "search" { return .tagsSearch }
            
            guard let rawTag = remainder.first else { return .unknown }
            let decodedTag = (rawTag.removingPercentEncoding ?? rawTag).ao3TagDecoded
            let tagRemainder = Array(remainder.dropFirst(1))
            return .tag(name: decodedTag, route: AO3TagRoute.dissect(remainder: tagRemainder))
            
        case "users":
            guard let username = remainder.first else { return .unknown }
            let userRemainder = Array(remainder.dropFirst(1))
            return .user(username: username, route: AO3UserRoute.dissect(remainder: userRemainder))
            
        case "collections":
            guard let name = remainder.first else { return .unknown }
            let collectionRemainder = Array(remainder.dropFirst(1))
            return .collection(name: name, route: AO3CollectionRoute.dissect(remainder: collectionRemainder))
            
        case "series":
            guard let idStr = remainder.first, let id = Int(idStr) else { return .unknown }
            let seriesRemainder = Array(remainder.dropFirst(1))
            return .series(id: id, route: AO3SeriesRoute.dissect(remainder: seriesRemainder))
            
        case "bookmarks":
            if remainder.first == "search" { return .bookmarksSearch }
            return .unknown
            
        case "people":
            if remainder.first == "search" { return .peopleSearch }
            return .unknown
            
        case "autocomplete":
            if let type = remainder.first { return .autocomplete(type: type) }
            return .unknown
            
        case "downloads":
            guard remainder.count >= 2, let workID = Int(remainder[0]) else { return .unknown }
            let filenameParts = remainder[1].split(separator: ".")
            guard filenameParts.count >= 2 else { return .unknown }
            let title = String(filenameParts[0]).replacingOccurrences(of: "_", with: " ")
            let format = String(filenameParts[1])
            return .download(workID: workID, title: title, format: format)
            
        case "admin_posts":
            if remainder.isEmpty { return .news(id: nil) }
            
            guard let id = Int(remainder[0]) else { return .unknown }
            let newsRemainder = Array(remainder.dropFirst(1))
            return .news(id: id, route: AO3NewsRoute.dissect(remainder: newsRemainder))
            
        default:
            return .unknown
        }
    }

    
    //-----------------------------------------------------------------------------------
    
    // MARK: GET Helpers
    
    internal func fetchPage<T: Codable & Sendable & AO3Response>(
        for url: URL,
        page: Int,
        parser: (String) throws -> [T]
    ) async throws -> AO3PaginatedResult<T> {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw AO3ClientError.invalidURLComponents
        }
        
        var queryItems = components.queryItems?.filter { $0.name != "page" } ?? []
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            throw AO3ClientError.invalidURL
        }
        
        let html = try await performRequest(url: finalURL)
        
        let items = try parser(html)
        let pagination = try AO3Parser.parsePagination(html: html)
        
        return AO3PaginatedResult(
            items: items,
            currentPage: pagination.currentPage,
            totalPages: pagination.totalPages
        )
    }
    
    internal func fetchAll<T: Codable & Sendable & AO3Response>(
        for url: URL,
        maxPages: Int?,
        progressHandler: ((_ currentPage: Int, _ totalPages: Int) -> Void)? = nil,
        parser: (String) throws -> [T]
    ) async throws -> [T] {
        var allItems: [T] = []
        var currentPage = 1
        var totalPages = 1
        
        repeat {
            let result = try await fetchPage(for: url, page: currentPage, parser: parser)
            allItems.append(contentsOf: result.items)
            totalPages = result.totalPages
            
            let effectiveTotal = {
                if let maxPages {
                    return min(totalPages, maxPages)
                } else { return totalPages }
            }()
            progressHandler?(currentPage, effectiveTotal)
            
            if let max = maxPages, currentPage >= max {
                break
            }
            
            currentPage += 1
        } while currentPage <= totalPages
        
        return allItems
    }
    
    @inline(__always)
    internal func fetchPaginated<T: Codable & Sendable & AO3Response>(
        url: URL?,
        page: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) throws -> [T]
    ) async throws -> AO3PaginatedResult<T> {
        guard let validURL = url else { throw AO3ClientError.invalidURL }
        
        let cacheKey = validURL.absoluteString + "&page=\(page)"
        
        var staleFallbackData: AO3PaginatedResult<T>? = nil
        
        if fallbackStrategy != .bypassCache,
           let response: AO3CacheResponse<AO3PaginatedResult<T>> = try? await cache.get(forKey: cacheKey) {
            
            if let data = response.data {
                if response.state == .upToDate || fallbackStrategy == .prioritiseCache {
                    return data
                }
                
                staleFallbackData = data
            }
        }
        
        do {
            let result = try await taskTracker.track(key: cacheKey) {
                return try await self.fetchPage(for: validURL, page: page, parser: parser)
            }
            try? await cache.set(result, forKey: cacheKey)
            return result
        } catch {
            if fallbackStrategy == .useCache, let staleFallbackData {
                return staleFallbackData
            }
            throw error
        }
    }
    
    @inline(__always)
    internal func fetchPaginated<T: Codable & Sendable & AO3Response>(
        endpoint: AO3Endpoint,
        page: Int,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) throws -> [T]
    ) async throws -> AO3PaginatedResult<T> {
        
        guard let url = endpoint.url() else {
            throw AO3ClientError.invalidEndpoint
        }
        
        return try await fetchPaginated(url: url, page: page, fallbackStrategy: fallbackStrategy, parser: parser)
    }

    
    @inline(__always)
    internal func fetchAllItems<T: Codable & Sendable & AO3Response>(
        url: URL?,
        maxPages: Int?,
        progressHandler: (@Sendable (Int, Int) -> Void)?,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) throws -> [T]
    ) async throws -> [T] {
        guard let validURL = url else { throw AO3ClientError.invalidURL }
        
        let limitSuffix = maxPages != nil ? "_limit_\(maxPages!)" : "_unlimited"
        let cacheKey = validURL.absoluteString + "_fetchAll" + limitSuffix
        
        var staleFallbackData: [T]? = nil
        
        if fallbackStrategy != .bypassCache,
           let response: AO3CacheResponse<[T]> = try? await cache.get(forKey: cacheKey) {
            
            if let data = response.data {
                if response.state == .upToDate || fallbackStrategy == .prioritiseCache {
                    progressHandler?(1, 1)
                    return data
                }
                
                staleFallbackData = data
            }
        }
        
        do {
            let result = try await taskTracker.track(key: cacheKey) {
                return try await self.fetchAll(for: validURL, maxPages: maxPages, progressHandler: progressHandler, parser: parser)
            }
            
            try? await cache.set(result, forKey: cacheKey)
            return result
        } catch {
            if fallbackStrategy == .useCache, let staleFallbackData {
                progressHandler?(1, 1)
                return staleFallbackData
            }
            throw error
        }
    }
    
    @inline(__always)
    internal func fetchAllItems<T: Codable & Sendable & AO3Response>(
        endpoint: AO3Endpoint,
        maxPages: Int?,
        progressHandler: (@Sendable (Int, Int) -> Void)?,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) throws -> [T]
    ) async throws -> [T] {
        
        guard let url = endpoint.url() else {
            throw AO3ClientError.invalidEndpoint
        }
        
        return try await fetchAllItems(url: url, maxPages: maxPages, progressHandler: progressHandler, fallbackStrategy: fallbackStrategy, parser: parser)
    }
    
    
    //-----------------------------------------------------------------------------------
    
    //MARK: Cache Helpers
    
    @inline(__always)
    internal func fetchCachedItem<T: Codable & Sendable>(
        url: URL?,
        cacheKey: String? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) async throws -> T
    ) async throws -> T {
        guard let validURL = url else { throw AO3ClientError.invalidURL }
        let key = cacheKey ?? validURL.absoluteString
        
        var staleFallbackData: T? = nil
        
        if fallbackStrategy != .bypassCache,
            let response: AO3CacheResponse<T> = try? await cache.get(forKey: key) {
            
            if let data = response.data {
                if response.state == .upToDate || fallbackStrategy == .prioritiseCache {
                    return data
                }
                
                staleFallbackData = data
            }
        }
        
        do {
            let result = try await taskTracker.track(key: key) {
                let html = try await self.performRequest(url: validURL, method: .get)
                return try await parser(html)
            }
            try? await cache.set(result, forKey: key)
            return result
        } catch {
            if fallbackStrategy == .useCache, let staleData = staleFallbackData {
                return staleData
            }
            throw error
        }
    }
    
    @inline(__always)
    internal func fetchCachedItem<T: Codable & Sendable>(
        endpoint: AO3Endpoint,
        cacheKey: String? = nil,
        fallbackStrategy: AO3CacheFallbackStrategy = .useCache,
        parser: @Sendable @escaping (String) async throws -> T
    ) async throws -> T {
        guard let url = endpoint.url() else {
            throw AO3ClientError.invalidURL
        }
        
        return try await fetchCachedItem(url: url, cacheKey: cacheKey, fallbackStrategy: fallbackStrategy, parser: parser)
    }



    //-----------------------------------------------------------------------------------
    
    //MARK: Networking
    
    internal func performRequest(
        url: URL,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [String: String]? = nil,
        maxRetries: Int = 3
    ) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

        if method == .post {
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        }
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let data = try await executeNetworkCall(request: request, maxRetries: maxRetries)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        guard !isAdultWarningPage(html: html) else {
            print("❌ AO3 adult content warning blocked fetch.")
            throw AO3ClientError.adultWarningBlocked
        }
        
        guard !isOnlyForRegisteredUsersPage(html: html) else {
            throw AO3ClientError.requiresRegistration
        }
        
        return html
    }
    
    private func executeNetworkCall(request: URLRequest, maxRetries: Int) async throws -> Data {
        var attempt = 0
        
        if cullRequestsOnOutage {
            let status = try? await AO3StatusMonitor.shared.currentStatus()
            if let isOperational = status?.isOperational, !isOperational {
                print("❌ AO3 Client: Request culled due to known system outage.")
                throw AO3ClientError.systemOutage
            }
        }
        
        while true {
            attempt += 1
            do {
                try await AO3RateLimiter.shared.waitIfNeeded()
                
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
                }
                
                return data
                
            } catch {
                if shouldRetry(for: error, currentAttempt: attempt, maxRetries: maxRetries) {
                    let backoffDelay = UInt64(attempt) * 1_000_000_000
                    try await Task.sleep(nanoseconds: backoffDelay)
                    continue
                } else {
                    throw error
                }
            }
        }
    }
    
    private func shouldRetry(for error: Error, currentAttempt: Int, maxRetries: Int) -> Bool {
        guard currentAttempt < maxRetries else { return false }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
                 URLError.Code(rawValue: 500), URLError.Code(rawValue: 502), URLError.Code(rawValue: 503), URLError.Code(rawValue: 504):
                return true
            default: return false
            }
        }
        return false
    }

    internal func isAdultWarningPage(html: String) -> Bool {
        return html.contains("This work could have adult content")
    }
    
    internal func isOnlyForRegisteredUsersPage(html: String) -> Bool {
        return html.contains("This work is only available to registered users of the Archive.")
    }
    
    internal enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
}


public extension URL {
    var isAO3: Bool { return AO3Client.isAO3(url: self) }
}

internal extension String {
    /// Encodes special characters into AO3's custom asterisk format for URLs.
    var ao3TagEncoded: String {
        self.replacingOccurrences(of: "/", with: "*s*")
            .replacingOccurrences(of: "&", with: "*a*")
            .replacingOccurrences(of: ".", with: "*d*")
            .replacingOccurrences(of: "?", with: "*q*")
    }
    
    /// Decodes AO3's custom asterisk format back into standard text.
    var ao3TagDecoded: String {
        self.replacingOccurrences(of: "*s*", with: "/")
            .replacingOccurrences(of: "*a*", with: "&")
            .replacingOccurrences(of: "*d*", with: ".")
            .replacingOccurrences(of: "*q*", with: "?")
    }
}
