//
//  SkillRotationEditorFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/9.
//

import Testing
import ComposableArchitecture
import Foundation

@testable import EorzeaToolkit

@MainActor
struct SkillRotationEditorFeatureTests {
    private let paladinID = BattleActionFixture.paladin.id

    // Slots already in the rotation use ids from 100 up, so they never collide with the ids
    // `.incrementing` gives new slots (0, 1, ...).
    private let first = RotationSlot(id: UUID(100), action: BattleActionFixture.fastBlade)
    private let second = RotationSlot(id: UUID(101), action: BattleActionFixture.riotBlade)
    private let third = RotationSlot(id: UUID(102), action: BattleActionFixture.fightOrFlight)
    private var existing: [RotationSlot] { [first, second, third] }

    // MARK: - Selection

    @Test func levelSelectedChangesTheLevelWithoutSaving() async {
        // No persistence override: saving would fail the test.
        let store = TestStore(initialState: BattleActionFixture.editorState()) {
            SkillRotationEditorFeature()
        }

        await store.send(.levelSelected(.level50)) {
            $0.selectedLevel = .level50
        }
    }

    @Test func categorySelectedChangesTheCategoryWithoutSaving() async {
        let store = TestStore(initialState: BattleActionFixture.editorState()) {
            SkillRotationEditorFeature()
        }

        await store.send(.categorySelected(.spell)) {
            $0.selectedCategory = .spell
        }
    }

    // MARK: - Adding

    @Test func actionAddedAppendsASlotAndSavesTheLevel() async {
        let savedCalls = LockIsolated<[SavedCall]>([])
        let store = makeStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [.level100: [first]]),
            savedCalls: savedCalls
        )
        let added = RotationSlot(id: UUID(0), action: BattleActionFixture.riotBlade)

        await store.send(.actionAdded(BattleActionFixture.riotBlade)) {
            $0.rotationsByLevel = [.level100: [first, added]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: [first, added]]))
        await store.finish()

        #expect(savedCalls.value == [SavedCall(jobID: paladinID, level: .level100, slots: [first, added])])
    }

    @Test func tinctureAddedAppendsASlotToTheSelectedLevel() async {
        let savedCalls = LockIsolated<[SavedCall]>([])
        let store = makeStore(
            initialState: BattleActionFixture.editorState(
                rotationsByLevel: [.level100: [first]],
                selectedLevel: .level50
            ),
            savedCalls: savedCalls
        )
        let added = RotationSlot(id: UUID(0), tincture: BattleActionFixture.strengthTincture)

        await store.send(.tinctureAdded(BattleActionFixture.strengthTincture)) {
            $0.rotationsByLevel = [.level100: [first], .level50: [added]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: [first], .level50: [added]]))
        await store.finish()

        // Only the selected level is saved.
        #expect(savedCalls.value == [SavedCall(jobID: paladinID, level: .level50, slots: [added])])
    }

    // AC-10
    @Test func addingTheSameActionTwiceKeepsTwoSlots() async {
        let savedCalls = LockIsolated<[SavedCall]>([])
        let store = makeStore(initialState: BattleActionFixture.editorState(), savedCalls: savedCalls)
        let firstAdded = RotationSlot(id: UUID(0), action: BattleActionFixture.fastBlade)
        let secondAdded = RotationSlot(id: UUID(1), action: BattleActionFixture.fastBlade)

        await store.send(.actionAdded(BattleActionFixture.fastBlade)) {
            $0.rotationsByLevel = [.level100: [firstAdded]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: [firstAdded]]))
        await store.send(.actionAdded(BattleActionFixture.fastBlade)) {
            $0.rotationsByLevel = [.level100: [firstAdded, secondAdded]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: [firstAdded, secondAdded]]))
        await store.finish()

        #expect(savedCalls.value.last == SavedCall(jobID: paladinID, level: .level100, slots: [firstAdded, secondAdded]))
    }

    // MARK: - Removing

    @Test func slotRemovedRemovesOnlyThatSlot() async {
        let savedCalls = LockIsolated<[SavedCall]>([])
        let store = makeStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [.level100: existing]),
            savedCalls: savedCalls
        )

        await store.send(.slotRemoved(id: second.id)) {
            $0.rotationsByLevel = [.level100: [first, third]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: [first, third]]))
        await store.finish()

        #expect(savedCalls.value == [SavedCall(jobID: paladinID, level: .level100, slots: [first, third])])
    }

    @Test func removingTheLastSlotRemovesTheLevel() async {
        let savedCalls = LockIsolated<[SavedCall]>([])
        let otherLevel = RotationSlot(id: UUID(200), action: BattleActionFixture.fastBlade)
        let store = makeStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [
                .level100: [first],
                .level50: [otherLevel],
            ]),
            savedCalls: savedCalls
        )

        await store.send(.slotRemoved(id: first.id)) {
            $0.rotationsByLevel = [.level50: [otherLevel]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level50: [otherLevel]]))
        await store.finish()

        #expect(savedCalls.value == [SavedCall(jobID: paladinID, level: .level100, slots: [])])
    }

    // MARK: - Moving

    @Test func slotMovedReordersTheLevelAndSavesIt() async {
        let savedCalls = LockIsolated<[SavedCall]>([])
        let store = makeStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [.level100: existing]),
            savedCalls: savedCalls
        )

        await store.send(.slotMoved(id: first.id, toIndex: 1)) {
            $0.rotationsByLevel = [.level100: [second, first, third]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: [second, first, third]]))
        await store.finish()

        #expect(savedCalls.value == [SavedCall(jobID: paladinID, level: .level100, slots: [second, first, third])])
    }

    @Test(arguments: [
        (100, 99, [101, 102, 100]),
        (102, -5, [102, 100, 101]),
    ])
    func slotMovedClampsTheDestination(movedID: Int, toIndex: Int, expectedIDs: [Int]) async {
        let slotsByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let expected = expectedIDs.compactMap { slotsByID[UUID($0)] }
        let savedCalls = LockIsolated<[SavedCall]>([])
        let store = makeStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [.level100: existing]),
            savedCalls: savedCalls
        )

        await store.send(.slotMoved(id: UUID(movedID), toIndex: toIndex)) {
            $0.rotationsByLevel = [.level100: expected]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: expected]))
        await store.finish()

        #expect(savedCalls.value == [SavedCall(jobID: paladinID, level: .level100, slots: expected)])
    }

    @Test(arguments: [
        (100, 0),   // already there
        (102, 99),  // clamped to where it already is
        (999, 0),   // not in the rotation
    ])
    func slotMovedDoesNothingWhenTheOrderWouldNotChange(movedID: Int, toIndex: Int) async {
        // No persistence override: saving would fail the test.
        let store = TestStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [.level100: existing])
        ) {
            SkillRotationEditorFeature()
        }

        await store.send(.slotMoved(id: UUID(movedID), toIndex: toIndex))
    }

    // MARK: - Clearing

    @Test func clearTappedRemovesTheSelectedLevelOnly() async {
        let savedCalls = LockIsolated<[SavedCall]>([])
        let otherLevel = RotationSlot(id: UUID(200), action: BattleActionFixture.fastBlade)
        let store = makeStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [
                .level100: existing,
                .level50: [otherLevel],
            ]),
            savedCalls: savedCalls
        )

        await store.send(.clearTapped) {
            $0.rotationsByLevel = [.level50: [otherLevel]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level50: [otherLevel]]))
        await store.finish()

        #expect(savedCalls.value == [SavedCall(jobID: paladinID, level: .level100, slots: [])])
    }

    // MARK: - Save failure

    @Test func saveFailureRestoresTheSavedSlots() async {
        // The database still holds only `first`, plus a slot of another job that must not leak in.
        let storedSlots = [
            StoredSlot(
                id: first.id, jobID: paladinID, level: 100, position: 0,
                reference: .action(BattleActionFixture.fastBlade.id)
            ),
            StoredSlot(
                id: UUID(300), jobID: BattleActionFixture.monk.id, level: 100, position: 0,
                reference: .action(BattleActionFixture.bootshine.id)
            ),
        ]
        let store = TestStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [.level100: [first]])
        ) {
            SkillRotationEditorFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.skillRotationPersistence.save = { _, _, _ in throw FetchError() }
            $0.skillRotationPersistence.load = { storedSlots }
        }
        let added = RotationSlot(id: UUID(0), action: BattleActionFixture.riotBlade)

        await store.send(.actionAdded(BattleActionFixture.riotBlade)) {
            $0.rotationsByLevel = [.level100: [first, added]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: [first, added]]))
        await store.receive(\.saveFailed)
        await store.receive(\.reloadResponse.success) {
            $0.rotationsByLevel = [.level100: [first]]
        }
        // The parent's cache is restored too.
        await store.receive(\.delegate, .rotationsChanged([.level100: [first]]))
    }

    @Test func reloadFailureKeepsTheRotationOnScreen() async {
        let store = TestStore(
            initialState: BattleActionFixture.editorState(rotationsByLevel: [.level100: [first]])
        ) {
            SkillRotationEditorFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.skillRotationPersistence.save = { _, _, _ in throw FetchError() }
            $0.skillRotationPersistence.load = { throw FetchError() }
        }
        let added = RotationSlot(id: UUID(0), action: BattleActionFixture.riotBlade)

        await store.send(.actionAdded(BattleActionFixture.riotBlade)) {
            $0.rotationsByLevel = [.level100: [first, added]]
        }
        await store.receive(\.delegate, .rotationsChanged([.level100: [first, added]]))
        await store.receive(\.saveFailed)
        await store.receive(\.reloadResponse.failure)
    }

    // MARK: - Helpers

    private struct SavedCall: Equatable {
        let jobID: Int
        let level: SkillRotationLevel
        let slots: [RotationSlot]
    }

    /// A store whose saves succeed and are recorded in `savedCalls`, with new slot ids from 0 up.
    private func makeStore(
        initialState: SkillRotationEditorFeature.State,
        savedCalls: LockIsolated<[SavedCall]>
    ) -> TestStoreOf<SkillRotationEditorFeature> {
        TestStore(initialState: initialState) {
            SkillRotationEditorFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.skillRotationPersistence.save = { jobID, level, slots in
                savedCalls.withValue { $0.append(SavedCall(jobID: jobID, level: level, slots: slots)) }
            }
        }
    }
}
