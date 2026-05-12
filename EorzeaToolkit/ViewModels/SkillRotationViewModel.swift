import Foundation

private struct PersistedSlot: Codable {
    let id: UUID
    let type: SlotType
    let actionId: Int?
    let tinctureId: Int?

    enum SlotType: String, Codable {
        case action
        case tincture
    }

    enum CodingKeys: String, CodingKey {
        case id, type, actionId, tinctureId
        case actionID = "action_id"
        case tinctureID = "tincture_id"
    }

    init(id: UUID, item: RotationItem) {
        self.id = id
        switch item {
        case .action(let action):
            self.type = .action
            self.actionId = action.id
            self.tinctureId = nil
        case .tincture(let tincture):
            self.type = .tincture
            self.actionId = nil
            self.tinctureId = tincture.id
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        actionId = try container.decodeIfPresent(Int.self, forKey: .actionID)
            ?? container.decodeIfPresent(Int.self, forKey: .actionId)
        tinctureId = try container.decodeIfPresent(Int.self, forKey: .tinctureID)
            ?? container.decodeIfPresent(Int.self, forKey: .tinctureId)
        type = try container.decodeIfPresent(SlotType.self, forKey: .type)
            ?? (tinctureId == nil ? .action : .tincture)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        switch type {
        case .action:
            try container.encodeIfPresent(actionId, forKey: .actionId)
        case .tincture:
            try container.encodeIfPresent(tinctureId, forKey: .tinctureId)
        }
    }
}

@Observable
final class SkillRotationViewModel {
    private(set) var jobs: [BattleJob] = []
    private(set) var tinctures: [Tincture] = []
    private(set) var tinctureStatJobs: [String: TinctureStatJob] = [:]

    /// 編輯中的 Rotation，依職業 id 分存。
    var rotationsByJobId: [Int: [RotationSlot]] = [:]

    @ObservationIgnored private let storageKey = "SkillRotation.rotationsByJobId.v1"
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var pendingPersistedRotations: [Int: [PersistedSlot]]?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.pendingPersistedRotations = Self.loadPersistedRotations(from: defaults, key: storageKey)
    }

    func load() {
        do {
            let data: BattleActionsData = try LocalDataService.load("battle_actions")
            jobs = data.jobs
            tinctures = data.tinctures
            tinctureStatJobs = data.tinctureStatJobs
            restoreRotations()
        } catch {
            print("Failed to load battle actions: \(error)")
        }
    }

    func rotation(for jobId: Int) -> [RotationSlot] {
        rotationsByJobId[jobId] ?? []
    }

    func addSkill(_ action: BattleAction, to jobId: Int) {
        rotationsByJobId[jobId, default: []].append(RotationSlot(action: action))
        persistRotations()
    }

    func addTincture(_ tincture: Tincture, to jobId: Int) {
        rotationsByJobId[jobId, default: []].append(RotationSlot(tincture: tincture))
        persistRotations()
    }

    func removeSlot(id: UUID, from jobId: Int) {
        rotationsByJobId[jobId]?.removeAll { $0.id == id }
        persistRotations()
    }

    func clearRotation(for jobId: Int) {
        rotationsByJobId[jobId] = []
        persistRotations()
    }

    func moveSlot(in jobId: Int, fromID: UUID, toIndex: Int) {
        guard var slots = rotationsByJobId[jobId],
              let fromIndex = slots.firstIndex(where: { $0.id == fromID }),
              fromIndex != toIndex else { return }
        let clampedTo = min(max(toIndex, 0), slots.count - 1)
        let slot = slots.remove(at: fromIndex)
        slots.insert(slot, at: clampedTo)
        rotationsByJobId[jobId] = slots
        persistRotations()
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

    func tinctures(for _: BattleJob) -> [Tincture] {
        tinctures
    }

    func statName(for tincture: Tincture) -> String {
        tinctureStatJobs[tincture.stat]?.nameTw ?? tincture.stat
    }

    // MARK: - Persistence

    private static func loadPersistedRotations(from defaults: UserDefaults, key: String) -> [Int: [PersistedSlot]]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            // UserDefaults 無法直接存 Int-keyed dictionary，JSON 會序列化為字串鍵。
            let decoded = try JSONDecoder().decode([String: [PersistedSlot]].self, from: data)
            var result: [Int: [PersistedSlot]] = [:]
            for (stringKey, slots) in decoded {
                guard let jobId = Int(stringKey) else { continue }
                result[jobId] = slots
            }
            return result
        } catch {
            print("Failed to decode persisted rotations: \(error)")
            return nil
        }
    }

    /// 依目前已載入的 jobs 將 PersistedSlot 還原為 RotationSlot。
    private func restoreRotations() {
        guard let persisted = pendingPersistedRotations else { return }
        pendingPersistedRotations = nil

        var actionIndex: [Int: [Int: BattleAction]] = [:]
        for job in jobs {
            var map: [Int: BattleAction] = [:]
            for action in job.actions {
                map[action.id] = action
            }
            actionIndex[job.id] = map
        }
        let tinctureIndex = Dictionary(uniqueKeysWithValues: tinctures.map { ($0.id, $0) })

        var restored: [Int: [RotationSlot]] = [:]
        for (jobId, slots) in persisted {
            guard let jobActions = actionIndex[jobId] else { continue }
            let reconstructed = slots.compactMap { slot -> RotationSlot? in
                switch slot.type {
                case .action:
                    guard let actionId = slot.actionId,
                          let action = jobActions[actionId] else { return nil }
                    return RotationSlot(id: slot.id, action: action)
                case .tincture:
                    guard let tinctureId = slot.tinctureId,
                          let tincture = tinctureIndex[tinctureId] else { return nil }
                    return RotationSlot(id: slot.id, tincture: tincture)
                }
            }
            if !reconstructed.isEmpty {
                restored[jobId] = reconstructed
            }
        }
        rotationsByJobId = restored
    }

    private func persistRotations() {
        var payload: [String: [PersistedSlot]] = [:]
        for (jobId, slots) in rotationsByJobId where !slots.isEmpty {
            payload[String(jobId)] = slots.map { PersistedSlot(id: $0.id, item: $0.item) }
        }
        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to persist rotations: \(error)")
        }
    }
}
