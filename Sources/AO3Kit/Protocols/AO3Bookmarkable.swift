//
//  AO3Bookmarkable.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 21.11.2026.
//

import Foundation

public protocol AO3Bookmarkable: AO3Response {
    var bookmarkableID: Int { get }
    var bookmarkTarget: AO3BookmarkTarget { get }
}
