//
//  SkillRotationPersistenceClientTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/8.
//

import Testing
import SwiftData
import Foundation

@testable import EorzeaToolkit

@MainActor
struct SkillRotationPersistenceClientTests {
    private let container: ModelContainer
    private let client: SkillRotationPersistenceClient
    private let paladinID = BattleActionFixture.paladin.id
    private let monkID = BattleActionFixture.monk.id

    init() throws {
        container = try ModelContainer(
            for: SkillRotationSlotRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        client = .live(container: container)
    }

    // MARK: - load

    @Test func loadReturnsEmptyWhenNothingSaved() async throws {
        let slots = try await client.load()
        #expect(slots.isEmpty)
    }

    @Test func loadSortsSlotsByJobLevelAndPosition() async throws {
        let context = container.mainContext
        let ids = (0..<4).map { _ in UUID() }
        
        context.insert(SkillRotationSlotRecord(id: ids[3], jobID: 20, level: 50,  position: 0, slotType: "action", actionID: 53))
        context.insert(SkillRotationSlotRecord(id: ids[2], jobID: 19, level: 100, position: 0, slotType: "action", actionID: 9))
        context.insert(SkillRotationSlotRecord(id: ids[1], jobID: 19, level: 50,  position: 1, slotType: "action", actionID: 15))
        context.insert(SkillRotationSlotRecord(id: ids[0], jobID: 19, level: 50,  position: 0, slotType: "action", actionID: 9))
        
        let slots = try await client.load()
        #expect(slots.map(\.id) == ids)
    }

    @Test func loadSkipsRecordsWithAnUnknownSlotType() async throws {
        container.mainContext.insert(SkillRotationSlotRecord(
            id: UUID(), jobID: paladinID, level: 50, position: 0,
            slotType: "unknown", actionID: BattleActionFixture.fastBlade.id
        ))
        let slots = try await client.load()
        #expect(slots.isEmpty)
    }

    @Test func loadSkipsRecordsWithoutTheReferenceTheirSlotTypeNeeds() async throws {
        let context = container.mainContext
        // Each record carries only the other kind's id.
        context.insert(SkillRotationSlotRecord(
            id: UUID(), jobID: paladinID, level: 50, position: 0,
            slotType: "action", tinctureID: BattleActionFixture.strengthTincture.id
        ))
        context.insert(SkillRotationSlotRecord(
            id: UUID(), jobID: paladinID, level: 50, position: 1,
            slotType: "tincture", actionID: BattleActionFixture.fastBlade.id
        ))

        let slots = try await client.load()

        #expect(slots.isEmpty)
    }

    // MARK: - save

    // AC-1, AC-2
    @Test func saveThenLoadRoundTripsActionsAndTinctures() async throws {
        let action = RotationSlot(action: BattleActionFixture.fastBlade)
        let tincture = RotationSlot(tincture: BattleActionFixture.strengthTincture)

        try await client.save(jobID: paladinID, level: .level100, slots: [action, tincture])

        #expect(try await client.load() == [
            StoredSlot(
                id: action.id, jobID: paladinID, level: 100, position: 0,
                reference: .action(BattleActionFixture.fastBlade.id)
            ),
            StoredSlot(
                id: tincture.id, jobID: paladinID, level: 100, position: 1,
                reference: .tincture(BattleActionFixture.strengthTincture.id)
            ),
        ])
    }

    // AC-3
    @Test func saveDeletesSlotsMissingFromTheList() async throws {
        let first = RotationSlot(action: BattleActionFixture.fastBlade)
        let second = RotationSlot(action: BattleActionFixture.riotBlade)
        let third = RotationSlot(action: BattleActionFixture.fightOrFlight)
        try await client.save(jobID: paladinID, level: .level100, slots: [first, second, third])

        try await client.save(jobID: paladinID, level: .level100, slots: [first, third])

        #expect(try await client.load().map(\.id) == [first.id, third.id])
        #expect(try !records().contains { $0.id == second.id })
    }

    @Test func saveRenumbersPositionsWithoutGaps() async throws {
        let first = RotationSlot(action: BattleActionFixture.fastBlade)
        let second = RotationSlot(action: BattleActionFixture.riotBlade)
        let third = RotationSlot(action: BattleActionFixture.fightOrFlight)
        try await client.save(jobID: paladinID, level: .level100, slots: [first, second, third])

        try await client.save(jobID: paladinID, level: .level100, slots: [first, third])

        #expect(try await client.load().map(\.position) == [0, 1])
    }

    // AC-4
    @Test func saveUpdatesPositionsWhenTheOrderChanges() async throws {
        let first = RotationSlot(action: BattleActionFixture.fastBlade)
        let second = RotationSlot(action: BattleActionFixture.riotBlade)
        let third = RotationSlot(action: BattleActionFixture.fightOrFlight)
        try await client.save(jobID: paladinID, level: .level100, slots: [first, second, third])

        try await client.save(jobID: paladinID, level: .level100, slots: [third, first, second])

        let slots = try await client.load()
        #expect(slots.map(\.id) == [third.id, first.id, second.id])
        #expect(slots.map(\.position) == [0, 1, 2])
        // The existing records are updated, not inserted again.
        #expect(try records().count == 3)
    }

    // AC-5
    @Test func saveWithNoSlotsDeletesEveryRecordOfThatJobAndLevel() async throws {
        let slots = [
            RotationSlot(action: BattleActionFixture.fastBlade),
            RotationSlot(tincture: BattleActionFixture.strengthTincture),
        ]
        try await client.save(jobID: paladinID, level: .level100, slots: slots)

        try await client.save(jobID: paladinID, level: .level100, slots: [])

        #expect(try await client.load().isEmpty)
        #expect(try records().isEmpty)
    }

    // AC-6, AC-7
    @Test func saveLeavesOtherLevelsAndJobsUntouched() async throws {
        let kept = RotationSlot(action: BattleActionFixture.fastBlade)
        let removed = RotationSlot(action: BattleActionFixture.riotBlade)
        let otherLevel = RotationSlot(action: BattleActionFixture.fightOrFlight)
        let otherJob = RotationSlot(action: BattleActionFixture.bootshine)
        try await client.save(jobID: paladinID, level: .level50, slots: [removed, kept])
        try await client.save(jobID: paladinID, level: .level60, slots: [otherLevel])
        try await client.save(jobID: monkID, level: .level50, slots: [otherJob])

        try await client.save(jobID: paladinID, level: .level50, slots: [kept])

        #expect(try await client.load() == [
            StoredSlot(
                id: kept.id, jobID: paladinID, level: 50, position: 0,
                reference: .action(BattleActionFixture.fastBlade.id)
            ),
            StoredSlot(
                id: otherLevel.id, jobID: paladinID, level: 60, position: 0,
                reference: .action(BattleActionFixture.fightOrFlight.id)
            ),
            StoredSlot(
                id: otherJob.id, jobID: monkID, level: 50, position: 0,
                reference: .action(BattleActionFixture.bootshine.id)
            ),
        ])
    }

    // AC-10
    @Test func saveStoresTheSameSkillTwiceAsSeparateSlots() async throws {
        let first = RotationSlot(action: BattleActionFixture.fastBlade)
        let second = RotationSlot(action: BattleActionFixture.fastBlade)
        try await client.save(jobID: paladinID, level: .level100, slots: [first, second])

        let saved = try await client.load()
        #expect(saved.map(\.id) == [first.id, second.id])
        #expect(saved.map(\.reference) == [
            .action(BattleActionFixture.fastBlade.id),
            .action(BattleActionFixture.fastBlade.id),
        ])

        try await client.save(jobID: paladinID, level: .level100, slots: [second])

        #expect(try await client.load().map(\.id) == [second.id])
    }

    // MARK: - Helpers

    private func records() throws -> [SkillRotationSlotRecord] {
        try container.mainContext.fetch(FetchDescriptor<SkillRotationSlotRecord>())
    }
}
