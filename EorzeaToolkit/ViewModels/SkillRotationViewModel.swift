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
    private(set) var hasLoadedJobs = false
    private(set) var loadError: String?

    /// 編輯中的 Rotation，依職業 id 與等級分存。
    var rotationsByJobId: [Int: [SkillRotationLevel: [RotationSlot]]] = [:]

    @ObservationIgnored private let storageKey = "SkillRotation.rotationsByJobId.v2"
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var pendingPersistedRotations: [Int: [SkillRotationLevel: [PersistedSlot]]]?

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
            hasLoadedJobs = true
            loadError = nil
        } catch {
            jobs = []
            tinctures = []
            tinctureStatJobs = [:]
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
        rotationsByJobId[jobId, default: [:]][level, default: []].append(RotationSlot(action: action))
        persistRotations()
    }

    func addTincture(_ tincture: Tincture, to jobId: Int, level: SkillRotationLevel) {
        rotationsByJobId[jobId, default: [:]][level, default: []].append(RotationSlot(tincture: tincture))
        persistRotations()
    }

    func removeSlot(id: UUID, from jobId: Int, level: SkillRotationLevel) {
        rotationsByJobId[jobId]?[level]?.removeAll { $0.id == id }
        removeEmptyRotation(for: jobId, level: level)
        persistRotations()
    }

    func clearRotation(for jobId: Int, level: SkillRotationLevel) {
        rotationsByJobId[jobId]?[level] = []
        removeEmptyRotation(for: jobId, level: level)
        persistRotations()
    }

    func moveSlot(in jobId: Int, level: SkillRotationLevel, fromID: UUID, toIndex: Int) {
        guard var slots = rotationsByJobId[jobId]?[level],
              let fromIndex = slots.firstIndex(where: { $0.id == fromID }),
              fromIndex != toIndex else { return }
        let clampedTo = min(max(toIndex, 0), slots.count - 1)
        let slot = slots.remove(at: fromIndex)
        slots.insert(slot, at: clampedTo)
        rotationsByJobId[jobId]?[level] = slots
        persistRotations()
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

    private static func loadPersistedRotations(
        from defaults: UserDefaults,
        key: String
    ) -> [Int: [SkillRotationLevel: [PersistedSlot]]]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            let decoded = try JSONDecoder().decode([String: [String: [PersistedSlot]]].self, from: data)
            var result: [Int: [SkillRotationLevel: [PersistedSlot]]] = [:]
            for (jobKey, rotationsByLevel) in decoded {
                guard let jobId = Int(jobKey) else { continue }
                for (levelKey, slots) in rotationsByLevel {
                    guard let levelValue = Int(levelKey),
                          let level = SkillRotationLevel(rawValue: levelValue) else { continue }
                    result[jobId, default: [:]][level] = slots
                }
            }
            return result
        } catch {
            print("Failed to decode persisted level rotations: \(error)")
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

        var restored: [Int: [SkillRotationLevel: [RotationSlot]]] = [:]
        for (jobId, rotationsByLevel) in persisted {
            guard let jobActions = actionIndex[jobId] else { continue }
            for (level, slots) in rotationsByLevel {
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
                    restored[jobId, default: [:]][level] = reconstructed
                }
            }
        }
        rotationsByJobId = restored
    }

    private func persistRotations() {
        var payload: [String: [String: [PersistedSlot]]] = [:]
        for (jobId, rotationsByLevel) in rotationsByJobId {
            var persistedLevels: [String: [PersistedSlot]] = [:]
            for level in SkillRotationLevel.allCases {
                guard let slots = rotationsByLevel[level], !slots.isEmpty else { continue }
                persistedLevels[String(level.rawValue)] = slots.map { PersistedSlot(id: $0.id, item: $0.item) }
            }
            if !persistedLevels.isEmpty {
                payload[String(jobId)] = persistedLevels
            }
        }
        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to persist rotations: \(error)")
        }
    }

    private func removeEmptyRotation(for jobId: Int, level: SkillRotationLevel) {
        guard rotationsByJobId[jobId]?[level]?.isEmpty == true else { return }
        rotationsByJobId[jobId]?[level] = nil
        if rotationsByJobId[jobId]?.isEmpty == true {
            rotationsByJobId[jobId] = nil
        }
    }
}
