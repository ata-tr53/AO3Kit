//
//  AO3IconPresentable.swift
//  AO3Kit
//
//  Created by İsmail Ata Bayraktutan on 12.11.2026.
//

public protocol AO3IconPresentable {
    var icon: AO3Image? { get }
}

internal extension AO3IconPresentable {
    var unwrappedIcon: AO3Image { return self.icon ?? .defaultLight }
}
