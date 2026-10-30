//
//  RelicWeaponSeriesFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import ComposableArchitecture

@Reducer
struct RelicWeaponSeriesFeature {
    enum Mode: CaseIterable, Equatable {
        case view
        case tracking
    }
    
    enum CancelID { case load }
    
    @ObservableState
    struct State: Equatable {
        var selectedMode: Mode = .view
        let series: WeaponSeries
        var selectedJob: String
        var completedStageIndices: Set<Int> = []
        var isProgressLoaded = false
        
        init(series: WeaponSeries) {
            self.series = series
            self.selectedJob = series.availableJobs.first ?? ""
        }
    }
    
    enum Action {
        case modeSelected(Mode)
        case jobSelected(String)
        case task
        case progressResponse(Result<Set<Int>, Error>)
        case saveFailed
        case stageToggled(Int)
    }
    
    @Dependency(\.relicWeaponProgress) var relicWeaponProgress
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .modeSelected(mode):
                state.selectedMode = mode
                return .none
            case let .jobSelected(job):
                state.selectedJob = job
                state.completedStageIndices = []
                state.isProgressLoaded = false
                return loadProgress(state)
            case .task:
                guard !state.isProgressLoaded else { return .none }
                return loadProgress(state)
            case let .progressResponse(.success(indices)):
                state.completedStageIndices = indices
                state.isProgressLoaded = true
                return .none
            case .progressResponse(.failure):
                return .none
            case .saveFailed:
                state.isProgressLoaded = false
                return loadProgress(state)
            case let .stageToggled(stageIndex):
                guard state.isProgressLoaded else { return .none }
                state.completedStageIndices.formSymmetricDifference([stageIndex])
                return .run { [seriesID = state.series.id,
                               job = state.selectedJob,
                               indices = state.completedStageIndices] send in
                    try await relicWeaponProgress.save(seriesID: seriesID, job: job, completedStageIndices: indices)
                } catch: { _, send in
                    await send(.saveFailed)
                }
            }
        }
    }
    
    private func loadProgress(_ state: State) -> Effect<Action> {
        .run { [seriesID = state.series.id, job = state.selectedJob] send in
            await send(.progressResponse(Result {
                try await relicWeaponProgress.load(seriesID: seriesID, job: job)
            }))
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}
