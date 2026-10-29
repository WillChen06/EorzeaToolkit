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
    }
    
    enum Action {
        case task
        case weaponSeriesResponse(Result<[WeaponSeries], Error>)
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
            }
        }
    }
}
