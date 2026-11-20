//
//  AO3FicModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

public protocol AO3FicModel: Identifiable, AO3Response, AO3Commentable, AO3Bookmarkable {
    var id: Int { get }
    
    var displayName: String { get }
}


public extension AO3FicModel {
    var url: URL? { AO3Endpoint.work(id: id, route: .main).url() }
    static var responseType: ResponseType { return .work }
    var commentableID: Int { id }
    var commentableType: AO3CommentableType { .work }
    var bookmarkableID: Int { id }
    var bookmarkTarget: AO3BookmarkTarget { .work(id: id) }
}
