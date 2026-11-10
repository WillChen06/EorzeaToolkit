//
//  SkillRotationEditorFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/9.
//

import Foundation
import ComposableArchitecture

@Reducer
struct SkillRotationEditorFeature {
    @ObservableState
    struct State: Equatable {
        var job: BattleJob
        var rotationsByLevel: [SkillRotationLevel: [RotationSlot]] = [:]
        var tinctures: [Tincture]
        var tinctureStatJobs: [String: TinctureStatJob]
        var selectedLevel: SkillRotationLevel = .defaultLevel
        var selectedCategory: SkillRotationCategory = .all
    }
    
    enum Action {
        case levelSelected(SkillRotationLevel)
        case categorySelected(SkillRotationCategory)
        case actionAdded(BattleAction)
        case tinctureAdded(Tincture)
        case slotRemoved(id: UUID)
        case slotMoved(id: UUID, toIndex: Int)
        case clearTapped
        case saveFailed
        case reloadResponse(Result<[StoredSlot], Error>)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case rotationsChanged([SkillRotationLevel: [RotationSlot]])
        }
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.skillRotationPersistence) var skillRotationPersistence
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .levelSelected(level):
                state.selectedLevel = level
                return .none
            case let .categorySelected(category):
                state.selectedCategory = category
                return .none
            case let .actionAdded(battleAction):
                let slot = RotationSlot(id: uuid(), action: battleAction)
                state.rotationsByLevel[state.selectedLevel, default: []].append(slot)
                return rotationChanged(&state)
            case let .tinctureAdded(tincture):
                let slot = RotationSlot(id: uuid(), tincture: tincture)
                state.rotationsByLevel[state.selectedLevel, default: []].append(slot)
                return rotationChanged(&state)
            case let .slotRemoved(id):
                state.rotationsByLevel[state.selectedLevel]?.removeAll { $0.id == id }
                return rotationChanged(&state)
            case let .slotMoved(id, toIndex):
                guard var slots = state.rotationsByLevel[state.selectedLevel],
                      let fromIndex = slots.firstIndex(where: { $0.id == id }) else { return .none }
                let destination = min(max(toIndex, 0), slots.count - 1)
                guard fromIndex != destination else { return .none }
                slots.insert(slots.remove(at: fromIndex), at: destination)
                state.rotationsByLevel[state.selectedLevel] = slots
                return rotationChanged(&state)
            case .clearTapped:
                state.rotationsByLevel[state.selectedLevel] = []
                return rotationChanged(&state)
            case .saveFailed:
                return .run { send in
                    await send(.reloadResponse(Result {
                        try await skillRotationPersistence.load()
                    }))
                }
            case let .reloadResponse(.success(storedSlots)):
                let rotations = StoredSlot.restore(storedSlots, jobs: [state.job], tinctures: state.tinctures)
                state.rotationsByLevel = rotations[state.job.id] ?? [:]
                return .send(.delegate(.rotationsChanged(state.rotationsByLevel)))
            case .reloadResponse(.failure):
                // Same as the view model: keep what is on screen.
                return .none
            case .delegate:
                return .none
            }
        }
    }
    
    private func rotationChanged(_ state: inout State) -> Effect<Action> {
        let level = state.selectedLevel
        if state.rotationsByLevel[level]?.isEmpty == true {
            state.rotationsByLevel[level] = nil
        }
        return .merge(
            .send(.delegate(.rotationsChanged(state.rotationsByLevel))),
            .run { [jobID = state.job.id, slots = state.rotation] send in
                do {
                    try await skillRotationPersistence.save(jobID: jobID, level: level, slots: slots)
                } catch {
                    await send(.saveFailed)
                }
            }
        )
    }
}

extension SkillRotationEditorFeature.State {
    var rotation: [RotationSlot] {
        rotationsByLevel[selectedLevel] ?? []
    }

    var filteredActions: [BattleAction] {
        guard selectedCategory != .item else { return [] }
        let category = selectedCategory.skillCategory
        return job.actions
            .filter { $0.level <= selectedLevel.rawValue && (category == nil || $0.skillCategory == category) }
            .sorted { $0.level == $1.level ? $0.id < $1.id : $0.level < $1.level }
    }
    
    var filteredTinctures: [Tincture] {
        switch selectedCategory {
        case .all, .item: return tinctures
        case .weaponskill, .spell, .ability: return []
        }
    }

    var showsTinctureSectionSeparator: Bool {
        selectedCategory == .all && !filteredActions.isEmpty && !filteredTinctures.isEmpty
    }
    
    func statName(for tincture: Tincture) -> String {
        tinctureStatJobs[tincture.stat]?.nameTw ?? tincture.stat
    }
}
