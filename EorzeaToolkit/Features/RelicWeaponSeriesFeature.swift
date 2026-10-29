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
    
    @ObservableState
    struct State: Equatable {
        var selectedMode: Mode = .view
        let series: WeaponSeries
        var selectedJob: String
        
        init(series: WeaponSeries) {
            self.series = series
            self.selectedJob = series.availableJobs.first ?? ""
        }
    }
    
    enum Action {
        case modeSelected(Mode)
        case jobSelected(String)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .modeSelected(mode):
                state.selectedMode = mode
                return .none
            case let .jobSelected(job):
                state.selectedJob = job
                return .none
            }
        }
    }
}
