//
//  ItemSearchFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/12.
//

import ComposableArchitecture

@Reducer
struct ItemSearchFeature {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }
    
    @ObservableState
    struct State: Equatable {
        var loadState: LoadState = .idle
        var catalog: ItemCatalog?
    }
    
    enum Action {
        case task
        case catalogResponse(Result<ItemCatalog, Error>)
        case refreshResponse(ItemCatalog?)
    }
    
    @Dependency(\.itemData) var itemData
    
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
                        try await itemData.load()
                    }))
                }
            case let .catalogResponse(.success(catalog)):
                state.loadState = .loaded
                state.catalog = catalog
                return .run { send in
                    let refreshed = try? await itemData.refresh(currentVersion: catalog.version)
                    await send(.refreshResponse(refreshed))
                }
            case let .catalogResponse(.failure(error)):
                state.loadState = .failed(error.localizedDescription)
                state.catalog = nil
                return .none
            case let .refreshResponse(catalog):
                guard let catalog else { return .none }
                state.catalog = catalog
                return .none
            }
        }
    }
}

