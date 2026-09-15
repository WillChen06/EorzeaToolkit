import Foundation
import SwiftData

@Observable
@MainActor
final class SkillRotationViewModel {
    private enum SlotType: String {
        case action
        case tincture
    }

    private(set) var jobs: [BattleJob] = []
    private(set) var tinctures: [Tincture] = []
    private(set) var tinctureStatJobs: [String: TinctureStatJob] = [:]
    private(set) var hasLoadedJobs = false
    private(set) var loadError: String?

    /// 編輯中的 Rotation，依職業 id 與等級分存。
    var rotationsByJobId: [Int: [SkillRotationLevel: [RotationSlot]]] = [:]

    @ObservationIgnored private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func load() {
        do {
            let data: BattleActionsData = try LocalDataService.load("battle_actions")
            jobs = data.jobs
            tinctures = data.tinctures
            tinctureStatJobs = data.tinctureStatJobs
            try restoreRotations()
            hasLoadedJobs = true
            loadError = nil
        } catch {
            jobs = []
            tinctures = []
            tinctureStatJobs = [:]
            rotationsByJobId = [:]
            hasLoadedJobs = true
            loadError = error.localizedDescription
        }
    }

    func rotation(for jobId: Int, level: SkillRotationLevel) -> [RotationSlot] {
        rotationsByJobId[jobId]?[level] ?? []
    }

    func savedLevels(for jobId: Int) -> [SkillRotationLevel] {
        guard let rotationsByLevel = rotationsByJobId[jobId] else { return [] }
        return SkillRotationLevel.displayCases.filter { level in
            rotationsByLevel[level]?.isEmpty == false
        }
    }

    func addSkill(_ action: BattleAction, to jobId: Int, level: SkillRotationLevel) {
        guard let modelContext else { return }
        do {
            let position = try nextPosition(for: jobId, level: level)
            let slot = RotationSlot(action: action)
            rotationsByJobId[jobId, default: [:]][level, default: []].append(slot)
            modelContext.insert(SkillRotationSlotRecord(
                id: slot.id,
                jobID: jobId,
                level: level.rawValue,
                position: position,
                slotType: SlotType.action.rawValue,
                actionID: action.id
            ))
            try modelContext.save()
        } catch {
            recoverFromPersistenceFailure()
        }
    }

    func addTincture(_ tincture: Tincture, to jobId: Int, level: SkillRotationLevel) {
        guard let modelContext else { return }
        do {
            let position = try nextPosition(for: jobId, level: level)
            let slot = RotationSlot(tincture: tincture)
            rotationsByJobId[jobId, default: [:]][level, default: []].append(slot)
            modelContext.insert(SkillRotationSlotRecord(
                id: slot.id,
                jobID: jobId,
                level: level.rawValue,
                position: position,
                slotType: SlotType.tincture.rawValue,
                tinctureID: tincture.id
            ))
            try modelContext.save()
        } catch {
            recoverFromPersistenceFailure()
        }
    }

    func removeSlot(id: UUID, from jobId: Int, level: SkillRotationLevel) {
        guard let modelContext else { return }
        do {
            let records = try fetchRecords(for: jobId, level: level)
            for record in records where record.id == id {
                modelContext.delete(record)
            }
            rotationsByJobId[jobId]?[level]?.removeAll { $0.id == id }
            removeEmptyRotation(for: jobId, level: level)
            try modelContext.save()
        } catch {
            recoverFromPersistenceFailure()
        }
    }

    func clearRotation(for jobId: Int, level: SkillRotationLevel) {
        guard let modelContext else { return }
        do {
            for record in try fetchRecords(for: jobId, level: level) {
                modelContext.delete(record)
            }
            rotationsByJobId[jobId]?[level] = []
            removeEmptyRotation(for: jobId, level: level)
            try modelContext.save()
        } catch {
            recoverFromPersistenceFailure()
        }
    }

    func moveSlot(in jobId: Int, level: SkillRotationLevel, fromID: UUID, toIndex: Int) {
        guard let modelContext,
              var slots = rotationsByJobId[jobId]?[level],
              let fromIndex = slots.firstIndex(where: { $0.id == fromID }),
              fromIndex != toIndex else { return }
        let clampedTo = min(max(toIndex, 0), slots.count - 1)
        let slot = slots.remove(at: fromIndex)
        slots.insert(slot, at: clampedTo)
        rotationsByJobId[jobId]?[level] = slots

        do {
            let records = try fetchRecords(for: jobId, level: level)
            for (position, slot) in slots.enumerated() {
                records.first { $0.id == slot.id }?.position = position
            }
            try modelContext.save()
        } catch {
            recoverFromPersistenceFailure()
        }
    }

    func actions(for job: BattleJob, level: SkillRotationLevel, category: SkillCategory?) -> [BattleAction] {
        let filtered: [BattleAction]
        if let category {
            filtered = job.actions.filter { $0.level <= level.rawValue && $0.skillCategory == category }
        } else {
            filtered = job.actions.filter { $0.level <= level.rawValue }
        }
        return filtered.sorted { $0.level == $1.level ? $0.id < $1.id : $0.level < $1.level }
    }

    func tinctures(for _: BattleJob) -> [Tincture] {
        tinctures
    }

    func statName(for tincture: Tincture) -> String {
        tinctureStatJobs[tincture.stat]?.nameTw ?? tincture.stat
    }

    // MARK: - Persistence

    private func restoreRotations() throws {
        guard let modelContext else {
            rotationsByJobId = [:]
            return
        }

        let records = try modelContext.fetch(FetchDescriptor<SkillRotationSlotRecord>()).sorted {
            if $0.jobID != $1.jobID { return $0.jobID < $1.jobID }
            if $0.level != $1.level { return $0.level < $1.level }
            if $0.position != $1.position { return $0.position < $1.position }
            return $0.id.uuidString < $1.id.uuidString
        }
        let actionIndex = Dictionary(uniqueKeysWithValues: jobs.map { job in
            (job.id, Dictionary(uniqueKeysWithValues: job.actions.map { ($0.id, $0) }))
        })
        let tinctureIndex = Dictionary(uniqueKeysWithValues: tinctures.map { ($0.id, $0) })

        var restored: [Int: [SkillRotationLevel: [RotationSlot]]] = [:]
        for record in records {
            guard let level = SkillRotationLevel(rawValue: record.level),
                  let jobActions = actionIndex[record.jobID] else { continue }

            let slot: RotationSlot?
            switch SlotType(rawValue: record.slotType) {
            case .action:
                slot = record.actionID.flatMap { jobActions[$0] }.map {
                    RotationSlot(id: record.id, action: $0)
                }
            case .tincture:
                slot = record.tinctureID.flatMap { tinctureIndex[$0] }.map {
                    RotationSlot(id: record.id, tincture: $0)
                }
            case nil:
                slot = nil
            }

            if let slot {
                restored[record.jobID, default: [:]][level, default: []].append(slot)
            }
        }
        rotationsByJobId = restored
    }

    private func fetchRecords(
        for jobId: Int,
        level: SkillRotationLevel
    ) throws -> [SkillRotationSlotRecord] {
        guard let modelContext else { return [] }
        let targetJobID = jobId
        let levelValue = level.rawValue
        let descriptor = FetchDescriptor<SkillRotationSlotRecord>(
            predicate: #Predicate { record in
                record.jobID == targetJobID && record.level == levelValue
            }
        )
        return try modelContext.fetch(descriptor)
    }

    private func nextPosition(for jobId: Int, level: SkillRotationLevel) throws -> Int {
        try fetchRecords(for: jobId, level: level).map(\.position).max().map { $0 + 1 } ?? 0
    }

    private func recoverFromPersistenceFailure() {
        modelContext?.rollback()
        try? restoreRotations()
    }

    private func removeEmptyRotation(for jobId: Int, level: SkillRotationLevel) {
        guard rotationsByJobId[jobId]?[level]?.isEmpty == true else { return }
        rotationsByJobId[jobId]?[level] = nil
        if rotationsByJobId[jobId]?.isEmpty == true {
            rotationsByJobId[jobId] = nil
        }
    }
}
