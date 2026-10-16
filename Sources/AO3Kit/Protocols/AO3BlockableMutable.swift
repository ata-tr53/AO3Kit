//
//  AO3BlockableMutable.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 6.10.2026.
//

public protocol AO3Mutable {
    var username: String { get }
    
    var unmuteActionID: Int? { get set }
}

public extension AO3Mutable {
    var isMuted: Bool { self.unmuteActionID != nil }
}

public protocol AO3Blockable {
    var username: String { get }
    
    var unblockActionID: Int? { get set }
}

public extension AO3Blockable {
    var isBlocked: Bool { self.unblockActionID != nil }
}
