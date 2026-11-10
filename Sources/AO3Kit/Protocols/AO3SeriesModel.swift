//
//  AO3SeriesModel.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 10.11.2026.
//

public protocol AO3SeriesModel: Identifiable, AO3Response {
    var id: Int { get }
    
    var name: String { get }
}
