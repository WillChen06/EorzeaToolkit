//
//  StoredSlotRestoreTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/8.
//

import Testing
import Foundation

@testable import EorzeaToolkit

struct StoredSlotRestoreTests {
    private let paladinID = BattleActionFixture.paladin.id
    private let monkID = BattleActionFixture.monk.id

    // AC-8
    @Test func restoresActionsAndTincturesWithTheirSlotIDsInOrder() {
        let first = stored(.action(BattleActionFixture.fastBlade.id), position: 0)
        let second = stored(.tincture(BattleActionFixture.strengthTincture.id), position: 1)
        let third = stored(.action(BattleActionFixture.riotBlade.id), position: 2)

        let rotations = restore([first, second, third])

        #expect(rotations == [
            paladinID: [
                .level100: [
                    RotationSlot(id: first.id, action: BattleActionFixture.fastBlade),
                    RotationSlot(id: second.id, tincture: BattleActionFixture.strengthTincture),
                    RotationSlot(id: third.id, action: BattleActionFixture.riotBlade),
                ],
            ],
        ])
    }

    // AC-9
    @Test func skipsSlotsWhoseActionOrTinctureIsMissingFromTheCatalog() {
        let valid = stored(.action(BattleActionFixture.fastBlade.id), position: 0)
        let missingAction = stored(.action(Int.max), position: 1)
        let missingTincture = stored(.tincture(Int.max), position: 2)

        let rotations = restore([valid, missingAction, missingTincture])

        #expect(rotations[paladinID]?[.level100]?.map(\.id) == [valid.id])
    }

    @Test func skipsActionsThatBelongToAnotherJob() {
        // Bootshine is a monk action, stored under the paladin.
        let slot = stored(.action(BattleActionFixture.bootshine.id), jobID: paladinID)

        #expect(restore([slot]).isEmpty)
    }

    @Test func skipsSlotsWithALevelTheEditorDoesNotOffer() {
        let slot = stored(.action(BattleActionFixture.fastBlade.id), level: 55)

        #expect(restore([slot]).isEmpty)
    }

    @Test func skipsSlotsOfAJobMissingFromTheCatalog() {
        // A tincture needs no job action, so only the unknown job can be the reason to skip it.
        let slot = stored(.tincture(BattleActionFixture.strengthTincture.id), jobID: 999)

        #expect(restore([slot]).isEmpty)
    }

    @Test func keepsJobsAndLevelsApart() {
        let paladin50 = stored(.action(BattleActionFixture.fastBlade.id), jobID: paladinID, level: 50)
        let paladin100 = stored(.action(BattleActionFixture.riotBlade.id), jobID: paladinID, level: 100)
        let monk50 = stored(.action(BattleActionFixture.bootshine.id), jobID: monkID, level: 50)
        // Tinctures are shared by every job.
        let monkTincture = stored(
            .tincture(BattleActionFixture.strengthTincture.id), jobID: monkID, level: 50, position: 1
        )

        let rotations = restore([paladin50, paladin100, monk50, monkTincture])

        #expect(rotations == [
            paladinID: [
                .level50: [RotationSlot(id: paladin50.id, action: BattleActionFixture.fastBlade)],
                .level100: [RotationSlot(id: paladin100.id, action: BattleActionFixture.riotBlade)],
            ],
            monkID: [
                .level50: [
                    RotationSlot(id: monk50.id, action: BattleActionFixture.bootshine),
                    RotationSlot(id: monkTincture.id, tincture: BattleActionFixture.strengthTincture),
                ],
            ],
        ])
    }

    // MARK: - Helpers

    private func stored(
        _ reference: StoredSlot.Reference,
        jobID: Int? = nil,
        level: Int = 100,
        position: Int = 0
    ) -> StoredSlot {
        StoredSlot(
            id: UUID(),
            jobID: jobID ?? paladinID,
            level: level,
            position: position,
            reference: reference
        )
    }

    private func restore(_ storedSlots: [StoredSlot]) -> [Int: [SkillRotationLevel: [RotationSlot]]] {
        StoredSlot.restore(
            storedSlots,
            jobs: [BattleActionFixture.paladin, BattleActionFixture.monk],
            tinctures: [BattleActionFixture.strengthTincture, BattleActionFixture.dexterityTincture]
        )
    }
}
