//
//  AO3Subscribable.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 5.10.2026.
//

import Foundation

public protocol AO3Subscribable: AO3Response {
    var subscribableID: Int { get }
    
    var subscriptionRecordID: Int? { get set }
}

public extension AO3Subscribable {
    var isSubscribed: Bool {
        return self.subscriptionRecordID != nil
    }
}
