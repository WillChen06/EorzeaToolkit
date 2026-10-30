//
//  PersistenceController.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/10/30.
//

import SwiftData

enum PersistenceController {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: RelicWeaponProgress.self, SkillRotationSlotRecord.self)
        } catch {
            fatalError("Could not create the model container: \(error)")
        }
    }()
}
