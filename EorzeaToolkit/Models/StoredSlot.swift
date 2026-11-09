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

extension StoredSlot {
    /// Rebuilds the rotations from the stored slots, keyed by job id and level.
    ///
    /// `storedSlots` must already be in rotation order, as `load()` returns them. A slot is
    /// skipped when its level is not one the editor offers, its job is not in the catalog, or the
    /// catalog has no action of that job or tincture with its id.
    static func restore(
        _ storedSlots: [StoredSlot],
        jobs: [BattleJob],
        tinctures: [Tincture]
    ) -> [Int: [SkillRotationLevel: [RotationSlot]]] {
        // An action is looked up among its own job's actions only.
        let actionsByJobID = Dictionary(
            jobs.map { job in
                (job.id, Dictionary(job.actions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }))
            },
            uniquingKeysWith: { first, _ in first }
        )
        let tincturesByID = Dictionary(tinctures.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var rotations: [Int: [SkillRotationLevel: [RotationSlot]]] = [:]
        for storedSlot in storedSlots {
            guard let level = SkillRotationLevel(rawValue: storedSlot.level),
                  let actions = actionsByJobID[storedSlot.jobID] else { continue }

            let slot: RotationSlot
            switch storedSlot.reference {
            case let .action(actionID):
                guard let action = actions[actionID] else { continue }
                slot = RotationSlot(id: storedSlot.id, action: action)
            case let .tincture(tinctureID):
                guard let tincture = tincturesByID[tinctureID] else { continue }
                slot = RotationSlot(id: storedSlot.id, tincture: tincture)
            }
            rotations[storedSlot.jobID, default: [:]][level, default: []].append(slot)
        }
        return rotations
    }
}
