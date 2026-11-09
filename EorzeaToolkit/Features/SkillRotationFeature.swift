//
//  SkillRotationFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/9.
//

import ComposableArchitecture

@Reducer
struct SkillRotationFeature {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }
    
    @ObservableState
    struct State: Equatable {
        var loadState: LoadState = .idle
        var jobs: IdentifiedArrayOf<BattleJob> = []
        var tinctures: [Tincture] = []
        var tinctureStatJobs: [String: TinctureStatJob] = [:]
        var rotationsByJobID: [Int: [SkillRotationLevel: [RotationSlot]]] = [:]
        var editor: SkillRotationEditorFeature.State?
        var selectedJobID: Int? {
            editor?.job.id
        }
    }
    
    struct Loaded: Equatable {
        var catalog: BattleActionsData
        var storedSlots: [StoredSlot]
    }
    
    enum Action {
        case task
        case loadResponse(Result<Loaded, Error>)
        case jobSelected(Int?)
        case editor(SkillRotationEditorFeature.Action)
    }
    
    @Dependency(\.skillRotationCatalog) var skillRotationCatalog
    @Dependency(\.skillRotationPersistence) var skillRotationPersistence
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                switch state.loadState {
                case .loading, .loaded:
                    return .none
                case .idle, .failed:
                    break
                }
                state.loadState = .loading
                return .run { send in
                    await send(
                        .loadResponse(Result {
                            async let catalog = skillRotationCatalog.fetch()
                            async let storedSlots = skillRotationPersistence.load()
                            return Loaded(
                                catalog: try await catalog,
                                storedSlots: try await storedSlots
                            )
                        })
                    )
                }
            case let .loadResponse(.success(loaded)):
                state.jobs = IdentifiedArray(uniqueElements: loaded.catalog.jobs)
                state.tinctures = loaded.catalog.tinctures
                state.tinctureStatJobs = loaded.catalog.tinctureStatJobs
                state.rotationsByJobID = StoredSlot.restore(
                    loaded.storedSlots,
                    jobs: loaded.catalog.jobs,
                    tinctures: loaded.catalog.tinctures
                )
                state.loadState = .loaded
                return .none
            case let .loadResponse(.failure(error)):
                state.loadState = .failed(error.localizedDescription)
                return .none
            case let .jobSelected(jobID):
                guard jobID != state.selectedJobID else { return .none }
                if let jobID, let job = state.jobs[id: jobID] {
                    state.editor = SkillRotationEditorFeature.State(
                        job: job,
                        rotationsByLevel: state.rotationsByJobID[jobID] ?? [:],
                        tinctures: state.tinctures,
                        tinctureStatJobs: state.tinctureStatJobs
                    )
                } else {
                    state.editor = nil
                }
                return .none
            case let .editor(.delegate(.rotationsChanged(rotations))):
                guard let jobID = state.selectedJobID else { return .none }
                state.rotationsByJobID[jobID] = rotations.isEmpty ? nil : rotations
                return .none
            case .editor:
                return .none
            }
        }
        .ifLet(\.editor, action: \.editor) {
            SkillRotationEditorFeature()
        }
    }
}

extension SkillRotationFeature.State {
    func savedLevels(for jobID: Int) -> [SkillRotationLevel] {
        guard let rotationsByLevel = rotationsByJobID[jobID] else { return [] }
        return SkillRotationLevel.displayCases.filter { rotationsByLevel[$0]?.isEmpty == false }
    }
}

