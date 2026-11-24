//
//  AO3SkinModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 25.11.2026.
//

import Foundation

public protocol AO3SkinModel: Identifiable, AO3Response, AO3IconPresentable {
    var id: Int { get }
    var title: String { get }
    var type: AO3SkinType { get }
}

public extension AO3SkinModel {
    var url: URL? { AO3Endpoint.skin(.show(id: id)).url() }
    static var responseType: ResponseType { .skin }
}
