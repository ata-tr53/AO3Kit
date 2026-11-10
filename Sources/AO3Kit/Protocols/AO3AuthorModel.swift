//
//  AO3AuthorModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

public protocol AO3AuthorModel: Identifiable, AO3Response {
    var username: String { get }
}

public extension AO3AuthorModel {
    var url: URL? { AO3Endpoint.user(username: self.username, route: .profile).url() }
    static var responseType: ResponseType { return .user }
}
