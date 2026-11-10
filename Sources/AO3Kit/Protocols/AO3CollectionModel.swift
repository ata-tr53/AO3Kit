//
//  AO3CollectionModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public protocol AO3CollectionModel: Identifiable, AO3Response {
    var id: String { get }
    
    var displayName: String { get }
}
