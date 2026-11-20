//
//  AO3SeriesModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

public protocol AO3SeriesModel: Identifiable, AO3Response, AO3Bookmarkable {
    var id: Int { get }
    
    var name: String { get }
}


public extension AO3SeriesModel {
    var url: URL? { AO3Endpoint.series(id: self.id, route: .main).url() }
    static var responseType: ResponseType { return .series }
    var bookmarkableID: Int { id }
    var bookmarkTarget: AO3BookmarkTarget { .series(id: id) }
}
