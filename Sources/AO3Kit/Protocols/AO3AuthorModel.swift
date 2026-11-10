//
//  AO3AuthorModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public protocol AO3AuthorModel: Identifiable, AO3Response {
    var username: String { get }
}
