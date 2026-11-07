//
//  AO3ClientError.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 14.09.2026.
//

import Foundation


public enum AO3ClientError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case noDataFound
    case invalidStatusCode
    case invalidJSON
    case invalidURLResponse
    case invalidURLQuery
    case invalidURLComponents
    case invalidURLComponentsQuery
    case adultWarningBlocked
    case invalidEndpoint
    case requiresRegistration
    case invalidCredentials
    case pseudNotFound
    case noSubscription
    case systemOutage
}

extension AO3ClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "The requested URL is invalid.")
            
        case .invalidResponse:
            return String(localized: "The server returned an unexpected response.")
            
        case .invalidData:
            return String(localized: "The response data is malformed or missing.")
            
        case .noDataFound:
            return String(localized: "The response data appears to be empty.")
            
        case .invalidStatusCode:
            return String(localized: "The server responded with an unsupported status code.")
            
        case .invalidJSON:
            return String(localized: "Failed to parse the server response.")
            
        case .invalidURLResponse:
            return String(localized: "The URL response is invalid.")
            
        case .invalidURLQuery:
            return String(localized: "The URL query parameters are invalid.")
            
        case .invalidURLComponents:
            return String(localized: "The URL components are invalid.")
            
        case .invalidURLComponentsQuery:
            return String(localized: "The URL components query is invalid.")
            
        case .adultWarningBlocked:
            return String(localized: "This content is behind an adult content warning. Adjust your preferences to proceed.")
            
        case .invalidEndpoint:
            return String(localized: "The requested endpoint is not available.")
            
        case .requiresRegistration:
            return String(localized: "This work is only available to registered users of the Archive.")
            
        case .invalidCredentials:
            return String(localized: "Wrong username or password.")
            
        case .pseudNotFound:
            return String(localized: "Pseud could not be found.")
            
        case .noSubscription:
            return String(localized: "This target is not subscribed already")
            
        case .systemOutage:
            return String(localized: "AO3 is experiencing issues, please try again later.")
        }
    }
}
