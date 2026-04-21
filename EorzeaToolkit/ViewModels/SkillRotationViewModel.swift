import Foundation

@Observable
final class SkillRotationViewModel {
    private(set) var jobs: [BattleJob] = []

    /// 編輯中的 Rotation，依職業 id 分存（in-memory）。
    var rotationsByJobId: [Int: [RotationSlot]] = [:]

    func load() {
        do {
            let data: BattleActionsData = try LocalDataService.load("battle_actions")
            jobs = data.jobs
        } catch {
            print("Failed to load battle actions: \(error)")
        }
    }

    func rotation(for jobId: Int) -> [RotationSlot] {
        rotationsByJobId[jobId] ?? []
    }

    func addSkill(_ action: BattleAction, to jobId: Int) {
        rotationsByJobId[jobId, default: []].append(RotationSlot(action: action))
    }

    func removeSlot(id: UUID, from jobId: Int) {
        rotationsByJobId[jobId]?.removeAll { $0.id == id }
    }

    func clearRotation(for jobId: Int) {
        rotationsByJobId[jobId] = []
    }

    func moveSlot(in jobId: Int, fromID: UUID, toIndex: Int) {
        guard var slots = rotationsByJobId[jobId],
              let fromIndex = slots.firstIndex(where: { $0.id == fromID }),
              fromIndex != toIndex else { return }
        let clampedTo = min(max(toIndex, 0), slots.count - 1)
        let slot = slots.remove(at: fromIndex)
        slots.insert(slot, at: clampedTo)
        rotationsByJobId[jobId] = slots
    }

    func actions(for job: BattleJob, category: SkillCategory?) -> [BattleAction] {
        let filtered: [BattleAction]
        if let category {
            filtered = job.actions.filter { $0.skillCategory == category }
        } else {
            filtered = job.actions
        }
        return filtered.sorted { $0.level == $1.level ? $0.id < $1.id : $0.level < $1.level }
    }
}
