//
//  RelicWeaponFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import ComposableArchitecture

@Reducer
struct RelicWeaponFeature {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }
    
    @ObservableState
    struct State: Equatable {
        var weaponSeriesList: IdentifiedArrayOf<WeaponSeries> = []
        var loadState: LoadState = .idle
        var seriesDetail: RelicWeaponSeriesFeature.State?
        var selectedSeriesID: String? { seriesDetail?.series.id }
    }
    
    enum Action {
        case task
        case weaponSeriesResponse(Result<[WeaponSeries], Error>)
        case seriesSelected(String?)
        case seriesDetail(RelicWeaponSeriesFeature.Action)
    }
    
    @Dependency(\.relicWeapon) var relicWeapon
    
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
                    await send(.weaponSeriesResponse(Result { try await relicWeapon.fetch() }))
                }
            case let .weaponSeriesResponse(result):
                switch result {
                case let .success(response):
                    state.weaponSeriesList = IdentifiedArray(uniqueElements: response)
                    state.loadState = .loaded
                case let .failure(error):
                    state.loadState = .failed(error.localizedDescription)
                }
                return .none
            case let .seriesSelected(seriesID):
                if let seriesID, let series = state.weaponSeriesList[id: seriesID] {
                    state.seriesDetail = RelicWeaponSeriesFeature.State(series: series)
                } else {
                    state.seriesDetail = nil
                }
                return .none
            case .seriesDetail:
                return .none
            }
        }
        .ifLet(\.seriesDetail, action: \.seriesDetail) {
            RelicWeaponSeriesFeature()
        }
    }
}
