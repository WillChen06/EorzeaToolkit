//
//  TreasureMapFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/4.
//

import ComposableArchitecture

@Reducer
struct TreasureMapFeature {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(TreasureMapCatalog)
        case failed(String)
    }
    
    @ObservableState
    struct State: Equatable {
        var loadState: LoadState = .idle
        var selectedMapID: String?
        var sortDirection: TreasureMapSortDirection = .descending
        var filter = TreasureMapFilter()
        
        var catalog: TreasureMapCatalog? {
            guard case let .loaded(catalog) = loadState else {
                return nil
            }
            return catalog
        }
        
        var displayedMaps: [TreasureMap] {
            TreasureMapQuery.sorted(
                TreasureMapQuery.filtered(catalog?.maps.elements ?? [], by: filter),
                direction: sortDirection
            )
        }
        
        var versionOptions: [Int] {
            TreasureMapQuery.versionOptions(from: catalog?.maps.elements ?? [])
        }
        
        var levelOptions: [Int] {
            TreasureMapQuery.levelOptions(from: catalog?.maps.elements ?? [])
        }
        
        var isFilterActive: Bool {
            filter.isActive
        }
        
        var activeFilterCount: Int {
            filter.activeFilterCount
        }
        
        var selectedMap: TreasureMap? {
            guard let selectedMapID else { return nil }
            return catalog?.maps[id: selectedMapID]
        }
    }
    
    enum Action {
        case task
        case catalogResponse(Result<TreasureMapCatalog, Error>)
        case mapSelected(String?)
        case sortButtonTapped
        case majorVersionToggled(Int)
        case levelToggled(Int)
        case clearFiltersButtonTapped
    }
    
    @Dependency(\.treasureMap) var treasureMap
    
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
                    await send(.catalogResponse(Result {
                        try await treasureMap.fetch()
                    }))
                }
            case let .catalogResponse(.success(catalog)):
                state.loadState = .loaded(catalog)
                return .none
            case let .catalogResponse(.failure(error)):
                state.loadState = .failed(error.localizedDescription)
                return .none
            case let .mapSelected(mapID):
                if let mapID, state.catalog?.maps[id: mapID] != nil {
                    state.selectedMapID = mapID
                } else {
                    state.selectedMapID = nil
                }
                return .none
            case .sortButtonTapped:
                state.sortDirection.toggle()
                return .none
            case let .majorVersionToggled(version):
                state.filter.selectedMajorVersions.formSymmetricDifference([version])
                return .none
            case let .levelToggled(level):
                state.filter.selectedLevels.formSymmetricDifference([level])
                return .none
            case .clearFiltersButtonTapped:
                state.filter = TreasureMapFilter()
                return .none
            }
        }
    }
}
