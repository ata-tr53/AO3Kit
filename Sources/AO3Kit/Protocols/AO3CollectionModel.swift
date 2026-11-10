//
//  AO3CollectionModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

import Foundation

public protocol AO3CollectionModel: Identifiable, AO3Response {
    var id: String { get }
    
    var displayName: String { get }
}


public extension AO3CollectionModel {
    var url: URL? { AO3Endpoint.collection(name: self.id, route: .main).url() }
    static var responseType: ResponseType { return .collection }
}
