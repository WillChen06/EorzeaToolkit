//
//  TreasureMapCatalogTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/3.
//

import Testing
@testable import EorzeaToolkit
import Foundation

private func makeCatalog(
    maps: [TreasureMap] = [],
    spots: [TreasureSpot] = [],
    zhNames: [Int: String] = [:],      // mapId → 地圖中文名
    mapInfos: [MapInfo] = [],
    zoneNames: [Int: String] = [:]     // zoneId → 地區名
) -> TreasureMapCatalog {
    TreasureMapCatalog(
        finalData:
            TreasureMapFinalData(
                maps: maps,
                zoneNames: Dictionary(uniqueKeysWithValues: zoneNames.map { (String($0.key), ZoneNameEntry(tw: $0.value))
                })
            ),
        spots: spots,
        zhNames: Dictionary(uniqueKeysWithValues: zhNames.map { (String($0.key), ZhMapName(zh: $0.value)) }),
        mapInfos: Dictionary(uniqueKeysWithValues: mapInfos.map { (String($0.id), $0) })
    )
}

private func spot(item: Int, map: Int, id: String = UUID().uuidString) -> TreasureSpot {
    TreasureSpot(id: id, coords: TreasureSpot.Coordinate(x: 0, y: 0, z: 0), map: map, partySize: 0, item: item)
}

private func mapInfo(id: Int, dungeon: Bool = false) -> MapInfo {
    MapInfo(id: id, image: "", placenameId: 0, sizeFactor: 100, territoryId: 0, dungeon: dungeon)
}

struct TreasureMapCatalogTests {
    @Test func zonesGroupSpotsByMapAndCountThem() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 10),
                spot(item: 1, map: 10),
                spot(item: 1, map: 20),
                spot(item: 2, map: 10),
            ],
            zhNames: [10: "中拉諾西亞", 20: "東拉諾西亞"]
        )

        #expect(catalog.zones(for: TreasureMapFixture.map(itemId: 1)) == [
            TreasureZone(mapId: 10, name: "中拉諾西亞", spotCount: 2),
            TreasureZone(mapId: 20, name: "東拉諾西亞", spotCount: 1),
        ])
    }

    @Test func zonesAreSortedByMapId() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 30),
                spot(item: 1, map: 10),
                spot(item: 1, map: 20),
            ]
        )

        #expect(catalog.zones(for: TreasureMapFixture.map(itemId: 1)).map(\.mapId) == [10, 20, 30])
    }
    
    @Test func zonesExcludeDungeonMaps() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 40),
                spot(item: 1, map: 10),
                spot(item: 1, map: 20),
            ],
            mapInfos: [
                mapInfo(id: 40, dungeon: true)
            ]
        )

        #expect(catalog.zones(for: TreasureMapFixture.map(itemId: 1)).map(\.mapId) == [10, 20])
    }

    @Test func zonesKeepMapsMissingFromMapInfos() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 10),
                spot(item: 1, map: 50),
            ],
            mapInfos: [
                mapInfo(id: 10)
            ]
        )

        #expect(catalog.zones(for: TreasureMapFixture.map(itemId: 1)).map(\.mapId) == [10, 50])
    }

    @Test func zoneNamesComeFromZhNamesByMapId() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 10),
                spot(item: 1, map: 20),
            ],
            zhNames: [10: "中拉諾西亞", 20: "東拉諾西亞", 30: "西拉諾西亞"]
        )

        #expect(catalog.zones(for: TreasureMapFixture.map(itemId: 1)).map(\.name) == ["中拉諾西亞", "東拉諾西亞"])
    }

    @Test func zoneNamesFallBackWhenMissingFromZhNames() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 10),
                spot(item: 1, map: 20),
            ],
            zhNames: [10: "中拉諾西亞"]
        )

        #expect(catalog.zones(for: TreasureMapFixture.map(itemId: 1)).map(\.name) == [
            "中拉諾西亞",
            L10n.TreasureMap.unknownRegion(id: 20),
        ])
    }

    @Test func zonesAreEmptyForMapWithoutSpots() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 10),
            ]
        )

        #expect(catalog.zones(for: TreasureMapFixture.map(itemId: 2)).isEmpty)
    }

    @Test func zonesAreEmptyWhenEverySpotIsInDungeon() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 40),
                spot(item: 1, map: 41),
            ],
            mapInfos: [
                mapInfo(id: 40, dungeon: true),
                mapInfo(id: 41, dungeon: true),
            ]
        )

        #expect(catalog.zones(for: TreasureMapFixture.map(itemId: 1)).isEmpty)
    }

    @Test func spotsOnlyIncludeTheMapAndZoneAsked() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 10, id: "a"),
                spot(item: 1, map: 10, id: "b"),
                spot(item: 1, map: 20, id: "c"),
                spot(item: 2, map: 10, id: "d"),
            ]
        )
        let zone = TreasureZone(mapId: 10, name: "中拉諾西亞", spotCount: 2)

        #expect(catalog.spots(for: TreasureMapFixture.map(itemId: 1), in: zone).map(\.id) == ["a", "b"])
    }

    @Test func spotsAreEmptyForZoneWithoutSpots() {
        let catalog = makeCatalog(
            spots: [
                spot(item: 1, map: 10),
            ]
        )
        let zone = TreasureZone(mapId: 20, name: "東拉諾西亞", spotCount: 0)

        #expect(catalog.spots(for: TreasureMapFixture.map(itemId: 1), in: zone).isEmpty)
    }

    @Test func mapInfoIsFoundByMapId() {
        let catalog = makeCatalog(
            mapInfos: [
                mapInfo(id: 10),
                mapInfo(id: 20, dungeon: true),
            ]
        )

        #expect(catalog.mapInfo(forMapId: 20) == mapInfo(id: 20, dungeon: true))
        #expect(catalog.mapInfo(forMapId: 30) == nil)
    }

    @Test func gatheringNodesTakeZoneNamesFromZoneNames() {
        let map = TreasureMapFixture.map(gatheringNodes: [
            GatheringNode(type: 0, job: "miner", zoneId: 100, mapId: 10, x: 12.3, y: 45.6),
            GatheringNode(type: 2, job: "botanist", zoneId: 200, mapId: 20, x: 7.8, y: 9.1),
        ])
        let catalog = makeCatalog(zoneNames: [100: "中拉諾西亞", 200: "黑衣森林中央林區"])

        #expect(catalog.gatheringNodes(for: map) == [
            GatheringNodeDisplay(type: 0, zoneName: "中拉諾西亞", zoneId: 100, mapId: 10, x: 12.3, y: 45.6),
            GatheringNodeDisplay(type: 2, zoneName: "黑衣森林中央林區", zoneId: 200, mapId: 20, x: 7.8, y: 9.1),
        ])
    }

    @Test func gatheringNodeZoneNamesFallBackWhenMissing() {
        let map = TreasureMapFixture.map(gatheringNodes: [
            GatheringNode(type: 0, job: "miner", zoneId: 100, mapId: 10, x: 12.3, y: 45.6),
            GatheringNode(type: 2, job: "botanist", zoneId: 200, mapId: 20, x: 7.8, y: 9.1),
        ])
        let catalog = makeCatalog(zoneNames: [100: "中拉諾西亞"])

        #expect(catalog.gatheringNodes(for: map).map(\.zoneName) == [
            "中拉諾西亞",
            L10n.TreasureMap.unknownRegionText,
        ])
    }

    @Test func mapsKeepTheirOrderFromFinalData() {
        let catalog = makeCatalog(maps: [
            TreasureMapFixture.map(grade: "G3"),
            TreasureMapFixture.map(grade: "G1"),
            TreasureMapFixture.map(grade: "G2"),
        ])

        #expect(catalog.maps.map(\.id) == ["G3", "G1", "G2"])
    }
}
