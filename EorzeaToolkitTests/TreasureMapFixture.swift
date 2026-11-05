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
        zones: [TreasureZone] = [],
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
            maxPartySize: 1,
            gatheringTypes: [],
            gatheringZoneIds: [],
            zones: zones,
            gatheringNodes: gatheringNodes
        )
    }

    static func catalog(maps: [TreasureMap] = filteringMaps) -> TreasureMapCatalog {
        TreasureMapCatalog(maps: maps)
    }

    static func node(
        type: Int = 0,
        zoneId: Int = 100,
        mapId: Int = 10,
        x: Double = 12.3,
        y: Double = 45.6,
        zoneName: String = "中拉諾西亞"
    ) -> GatheringNode {
        GatheringNode(
            type: type,
            job: type <= 1 ? .miner : .botanist,
            zoneId: zoneId,
            mapId: mapId,
            x: x,
            y: y,
            zoneName: zoneName,
            image: "https://xivapi.com/m/f1f1/f1f1.00.jpg",
            sizeFactor: 100
        )
    }
}
