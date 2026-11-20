//
//  AO3CommentModerationAction.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 20.11.2026.
//

import Foundation

public enum AO3CommentModerationAction: String, Sendable, Equatable, Hashable, CaseIterable {
    case approve
    case reject
    case review
    case freeze
    case unfreeze
    case hide
    case unhide

    internal func endpoint(for commentID: Int) -> AO3Endpoint {
        switch self {
        case .approve: return .comments(.approve(id: commentID))
        case .reject: return .comments(.reject(id: commentID))
        case .review: return .comments(.review(id: commentID))
        case .freeze: return .comments(.freeze(id: commentID))
        case .unfreeze: return .comments(.unfreeze(id: commentID))
        case .hide: return .comments(.hide(id: commentID))
        case .unhide: return .comments(.unhide(id: commentID))
        }
    }
}
