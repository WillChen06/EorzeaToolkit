//
//  TreasureMapFixture.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/3.
//

@testable import EorzeaToolkit

enum TreasureMapFixture {
    static let filteringMaps = [
        map(grade: "G1", level: 40, expansion: "2.1"),
        map(grade: "G2", level: 80, expansion: "6.0"),
        map(grade: "G3", level: 90, expansion: "6.3"),
        map(grade: "G4", level: 100, expansion: "7.0"),
        map(grade: "G5", level: 70, expansion: "7.3"),
        map(grade: "G6", level: 90, expansion: "5.0")
    ]

    static func map(
        grade: String = "G1",
        level: Int = 40,
        expansion: String = "2.1",
        itemId: Int = 1,
        gatheringNodes: [GatheringNode] = []
    ) -> TreasureMap {
        TreasureMap(
            id: grade,
            itemId: itemId,
            grade: grade,
            name: grade,
            level: level,
            expansion: expansion,
            type: .solo,
            gatheringTypes: [],
            gatheringZoneIds: [],
            gatheringNodes: gatheringNodes
        )
    }
}
