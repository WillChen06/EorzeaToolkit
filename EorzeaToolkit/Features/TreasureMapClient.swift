//
//  TreasureMapClient.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/3.
//

import ComposableArchitecture

@DependencyClient
struct TreasureMapClient: Sendable {
    var fetch: @Sendable () async throws -> TreasureMapCatalog
}

extension TreasureMapClient: TestDependencyKey {
    static let testValue = Self()
}

extension TreasureMapClient: DependencyKey {
    static let liveValue = Self(
        fetch: {
            let finalData: TreasureMapFinalData = try LocalDataService.load("treasure_maps_final")
            let spots: [TreasureSpot] = try LocalDataService.load("treasures")
            let zhNames = (try LocalDataService.load("zh-maps") as ZhMapNames).names
            let mapInfos: [String: MapInfo] = try LocalDataService.load("maps")
            
            return TreasureMapCatalog(
                finalData: finalData,
                spots: spots,
                zhNames: zhNames,
                mapInfos: mapInfos
            )
        }
    )
}

extension DependencyValues {
    var treasureMap: TreasureMapClient {
        get { self[TreasureMapClient.self] }
        set { self[TreasureMapClient.self] = newValue }
    }
}

struct TreasureMapCatalog: Equatable, Sendable {
    let maps: IdentifiedArrayOf<TreasureMap>
    
    private let spotsByItem: [Int: [Int: [TreasureSpot]]] // itemId → mapId → spots
    private let zonesByItemId: [Int: [TreasureZone]]
    private let mapInfosById: [Int: MapInfo]
    private let zoneNamesById: [Int: String]  // zoneId → 繁中地區名
    
    init(
        finalData: TreasureMapFinalData,
        spots: [TreasureSpot],
        zhNames: [String: ZhMapName],
        mapInfos: [String: MapInfo]
    ) {
        maps = IdentifiedArray(uniqueElements: finalData.maps)
        zoneNamesById = Dictionary(uniqueKeysWithValues: finalData.zoneNames.compactMap { key, entry in
            Int(key).map { ($0, entry.tw) }
        })
        let mapInfosById = Dictionary(uniqueKeysWithValues: mapInfos.compactMap { key, info in
            Int(key).map { ($0, info) }
        })
        self.mapInfosById = mapInfosById
        
        // 依 (item, map) 分組點位
        var spotsByItem: [Int: [Int: [TreasureSpot]]] = [:]
        for spot in spots {
            spotsByItem[spot.item, default: [:]][spot.map, default: []].append(spot)
        }

        // 組合地區資訊
        zonesByItemId = spotsByItem.mapValues { spotsByMap in
            spotsByMap.compactMap { mapId, mapSpots -> TreasureZone? in
                guard mapInfosById[mapId]?.dungeon != true else { return nil }
                let name = zhNames[String(mapId)]?.zh ?? L10n.TreasureMap.unknownRegion(id: mapId)
                return TreasureZone(mapId: mapId, name: name, spotCount: mapSpots.count)
            }
            .sorted { $0.mapId < $1.mapId }
        }
        self.spotsByItem = spotsByItem
    }
    
    func zones(for map: TreasureMap) -> [TreasureZone] {
        zonesByItemId[map.itemId] ?? []
    }

    func spots(for map: TreasureMap, in zone: TreasureZone) -> [TreasureSpot] {
        spotsByItem[map.itemId]?[zone.mapId] ?? []
    }

    func mapInfo(forMapId mapId: Int) -> MapInfo? {
        mapInfosById[mapId]
    }
    
    func mapInfos(for nodes: [GatheringNodeDisplay]) -> [Int: MapInfo] {
        Dictionary(
            nodes.compactMap { node in mapInfo(forMapId: node.mapId).map { (node.mapId, $0) } },
            uniquingKeysWith: { first, _ in first }
        )
    }

    func gatheringNodes(for map: TreasureMap) -> [GatheringNodeDisplay] {
        map.gatheringNodes.map { node in
            let zoneName = zoneNamesById[node.zoneId] ?? L10n.TreasureMap.unknownRegionText
            return GatheringNodeDisplay(
                type: node.type, zoneName: zoneName, zoneId: node.zoneId, mapId: node.mapId, x: node.x, y: node.y
            )
        }
    }
}

