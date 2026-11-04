//
//  GatheringNodesFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/4.
//

import ComposableArchitecture

@Reducer
struct GatheringNodesFeature {
    @ObservableState
    struct State: Equatable {
        let nodes: [GatheringNodeDisplay]
        let map: TreasureMap
        let mapInfos: [Int: MapInfo]
        var selectedNodeID: GatheringNodeDisplay.ID?
        var selectedNode: GatheringNodeDisplay? {
            nodes.first { $0.id == selectedNodeID }
        }
    }
    
    enum Action {
        case closeButtonTapped
        case nodeSelected(GatheringNodeDisplay?)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                return .run { _ in
                    await self.dismiss()
                }
            case let .nodeSelected(node):
                if let node, state.nodes.contains(where: { $0.id == node.id }) {
                    state.selectedNodeID = node.id
                } else {
                    state.selectedNodeID = nil
                }
                return .none
            }
        }
    }
}

