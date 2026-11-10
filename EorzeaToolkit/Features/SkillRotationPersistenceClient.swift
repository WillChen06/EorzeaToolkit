//
//  SkillRotationPersistenceClient.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/6.
//

import ComposableArchitecture
import SwiftData
import Foundation

private enum SlotType: String {
    case action
    case tincture
}

@DependencyClient
struct SkillRotationPersistenceClient: Sendable {
    var load: @Sendable () async throws -> [StoredSlot]
    var save: @Sendable (_ jobID: Int, _ level: SkillRotationLevel, _ slots: [RotationSlot]) async throws -> Void
}

extension SkillRotationPersistenceClient: TestDependencyKey {
    static let testValue = Self()
}

extension SkillRotationPersistenceClient: DependencyKey {
    static let liveValue = Self.live(container: PersistenceController.container)
    
    static let previewValue = Self.live(
        container: try! ModelContainer(
            for: SkillRotationSlotRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    )
    
    static func live(container: ModelContainer) -> Self {
        Self(
            load: {
                try await MainActor.run {
                    let records = try container.mainContext.fetch(allRecordsDescriptor())
                    
                    return records.compactMap(storedSlot(from:))
                }
            },
            save: { jobID, level, slots in
                try await MainActor.run {
                    let context = container.mainContext
                    do {
                        let records = try context.fetch(descriptor(jobID: jobID, level: level))
                        var remaining = Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                        
                        for (position, slot) in slots.enumerated() {
                            if let record = remaining.removeValue(forKey: slot.id) {
                                record.position = position
                            } else {
                                context.insert(makeRecord(for: slot, jobID: jobID, level: level, position: position))
                            }
                        }
                        
                        for record in remaining.values {
                            context.delete(record)
                        }
                        
                        try context.save()
                    } catch {
                        context.rollback()
                        throw error
                    }
                }
            }
        )
    }
    
    private static func allRecordsDescriptor() -> FetchDescriptor<SkillRotationSlotRecord> {
        FetchDescriptor<SkillRotationSlotRecord>(
            sortBy: [
                SortDescriptor(\.jobID),
                SortDescriptor(\.level),
                SortDescriptor(\.position),
            ]
        )
    }
    
    private static func descriptor(jobID: Int, level: SkillRotationLevel) -> FetchDescriptor<SkillRotationSlotRecord> {
        let levelValue = level.rawValue
        return FetchDescriptor<SkillRotationSlotRecord>(
            predicate: #Predicate { record in
                record.jobID == jobID && record.level == levelValue
            }
        )
    }
    
    private static func storedSlot(from record: SkillRotationSlotRecord) -> StoredSlot? {
        let reference: StoredSlot.Reference
        switch (SlotType(rawValue: record.slotType), record.actionID, record.tinctureID) {
        case let (.action?, actionID?, _):
            reference = .action(actionID)
        case let (.tincture?, _, tinctureID?):
            reference = .tincture(tinctureID)
        default:
            return nil
        }
        return StoredSlot(
            id: record.id,
            jobID: record.jobID,
            level: record.level,
            position: record.position,
            reference: reference
        )
    }
    
    private static func makeRecord(
        for slot: RotationSlot, jobID: Int, level: SkillRotationLevel, position: Int
    ) -> SkillRotationSlotRecord {
        switch slot.item {
        case let .action(action):
            return SkillRotationSlotRecord(
                id: slot.id, jobID: jobID, level: level.rawValue, position: position,
                slotType: SlotType.action.rawValue, actionID: action.id
            )
        case let .tincture(tincture):
            return SkillRotationSlotRecord(
                id: slot.id, jobID: jobID, level: level.rawValue, position: position,
                slotType: SlotType.tincture.rawValue, tinctureID: tincture.id
            )
        }
    }
}

extension DependencyValues {
    var skillRotationPersistence: SkillRotationPersistenceClient {
        get { self[SkillRotationPersistenceClient.self] }
        set { self[SkillRotationPersistenceClient.self] = newValue }
    }
}
