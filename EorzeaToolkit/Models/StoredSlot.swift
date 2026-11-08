//
//  StoredSlot.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/6.
//

import Foundation

struct StoredSlot: Equatable, Identifiable, Sendable {
    enum Reference: Equatable, Sendable {
        case action(Int)
        case tincture(Int)
    }
    
    let id: UUID
    let jobID: Int
    let level: Int
    let position: Int
    let reference: Reference
}
