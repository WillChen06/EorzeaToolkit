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
    private let spotsByKey: [String: [TreasureSpot]]  // "itemId-mapId" → spots
    private let mapInfosByKey: [String: MapInfo]
    private var zonesByItemId: [Int: [TreasureZone]] = [:]
    private let zoneNames: [String: ZoneNameEntry]
    
    init(
        finalData: TreasureMapFinalData,
        spots: [TreasureSpot],
        zhNames: [String: ZhMapName],
        mapInfos: [String: MapInfo]
    ) {
        maps = IdentifiedArray(uniqueElements: finalData.maps)
        zoneNames = finalData.zoneNames
        mapInfosByKey = mapInfos
        
        // 依 (item, map) 分組點位
        var groupedSpots: [String: [TreasureSpot]] = [:]
        var spotCountByItem: [Int: [Int: Int]] = [:]  // [itemId: [mapId: count]]

        for spot in spots {
            let key = "\(spot.item)-\(spot.map)"
            groupedSpots[key, default: []].append(spot)
            spotCountByItem[spot.item, default: [:]][spot.map, default: 0] += 1
        }
        spotsByKey = groupedSpots

        // 組合地區資訊
        for (itemId, mapCounts) in spotCountByItem {
            let zones = mapCounts.compactMap { (mapId, count) -> TreasureZone? in
                if let info = mapInfos[String(mapId)], info.dungeon {
                    return nil
                }
                let name = zhNames[String(mapId)]?.zh ?? L10n.TreasureMap.unknownRegion(id: mapId)
                return TreasureZone(mapId: mapId, name: name, spotCount: count)
            }
            .sorted { $0.mapId < $1.mapId }

            zonesByItemId[itemId] = zones
        }
    }
    
    func zones(for map: TreasureMap) -> [TreasureZone] {
        zonesByItemId[map.itemId] ?? []
    }

    func spots(for map: TreasureMap, in zone: TreasureZone) -> [TreasureSpot] {
        spotsByKey["\(map.itemId)-\(zone.mapId)"] ?? []
    }

    func mapInfo(forMapId mapId: Int) -> MapInfo? {
        mapInfosByKey[String(mapId)]
    }

    func gatheringNodes(for map: TreasureMap) -> [GatheringNodeDisplay] {
        map.gatheringNodes.map { node in
            let zoneName = zoneNames[String(node.zoneId)]?.tw ?? L10n.TreasureMap.unknownRegionText
            return GatheringNodeDisplay(
                type: node.type, zoneName: zoneName, zoneId: node.zoneId, mapId: node.mapId, x: node.x, y: node.y
            )
        }
    }
}

