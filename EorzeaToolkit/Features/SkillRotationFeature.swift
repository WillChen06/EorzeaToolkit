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
        var selectedJobID: Int?
    }
    
    struct Loaded: Equatable {
        var catalog: BattleActionsData
        var storedSlots: [StoredSlot]
    }
    
    enum Action {
        case task
        case loadResponse(Result<Loaded, Error>)
        case jobSelected(Int?)
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
                if let jobID, state.jobs[id: jobID] != nil {
                    state.selectedJobID = jobID
                } else {
                    state.selectedJobID = nil
                }
                return .none
            }
        }
    }
}

