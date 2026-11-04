//
//  GatheringNodesFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/4.
//

import Testing
import ComposableArchitecture

@testable import EorzeaToolkit

@MainActor
struct GatheringNodesFeatureTests {
    private let nodes = [
        GatheringNodeDisplay(type: 0, zoneName: "中拉諾西亞", zoneId: 100, mapId: 10, x: 12.3, y: 45.6),
        GatheringNodeDisplay(type: 2, zoneName: "黑衣森林中央林區", zoneId: 200, mapId: 20, x: 7.8, y: 9.1),
    ]

    private func makeStore(selectedNodeID: GatheringNodeDisplay.ID? = nil) -> TestStoreOf<GatheringNodesFeature> {
        TestStore(
            initialState: GatheringNodesFeature.State(
                nodes: nodes,
                map: TreasureMapFixture.map(),
                mapInfos: [:],
                selectedNodeID: selectedNodeID
            )
        ) {
            GatheringNodesFeature()
        }
    }

    @Test func selectingNodeSetsSelectedNode() async throws {
        let node = try #require(nodes.last)
        let store = makeStore()

        await store.send(.nodeSelected(node)) {
            $0.selectedNodeID = node.id
        }

        #expect(store.state.selectedNode == node)
    }

    @Test func selectingNilClearsSelection() async throws {
        let node = try #require(nodes.first)
        let store = makeStore(selectedNodeID: node.id)

        await store.send(.nodeSelected(nil)) {
            $0.selectedNodeID = nil
        }

        #expect(store.state.selectedNode == nil)
    }

    @Test func selectingUnknownNodeClearsSelection() async throws {
        let node = try #require(nodes.first)
        let unknownNode = GatheringNodeDisplay(type: 0, zoneName: "", zoneId: 900, mapId: 99, x: 1, y: 1)
        let store = makeStore(selectedNodeID: node.id)

        await store.send(.nodeSelected(unknownNode)) {
            $0.selectedNodeID = nil
        }

        #expect(store.state.selectedNode == nil)
    }
}
