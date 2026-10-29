//
//  RelicWeaponFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import ComposableArchitecture

@Reducer
struct RelicWeaponFeature {
    @ObservableState
    struct State: Equatable {
        var weaponSeriesList: IdentifiedArrayOf<WeaponSeries> = []
        var loadError: String?
        var hasLoadedWeapons: Bool
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
                return .run { send in
                    await send(.weaponSeriesResponse(Result { try await relicWeapon.fetch() }))
                }
            case let .weaponSeriesResponse(result):
                state.hasLoadedWeapons = true
                switch result {
                case let .success(response):
                    state.weaponSeriesList = IdentifiedArray(uniqueElements: response)
                    state.loadError = nil
                case let .failure(error):
                    state.loadError = error.localizedDescription
                }
                return .none
            }
        }
    }
}
