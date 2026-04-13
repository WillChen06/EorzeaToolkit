import Foundation

@Observable
final class TreasureMapViewModel {
    private(set) var maps: [TreasureMap] = []
    private(set) var zonesByItemId: [Int: [TreasureZone]] = [:]
    private(set) var zoneNames: [String: ZoneNameEntry] = [:]
    private var spotsByKey: [String: [TreasureSpot]] = [:]  // "itemId-mapId" → spots
    private var mapInfosByKey: [String: MapInfo] = [:]

    func loadMaps() {
        do {
            let finalData: TreasureMapFinalData = try LocalDataService.load("treasure_maps_final")
            maps = finalData.maps
            zoneNames = finalData.zoneNames

            let spots: [TreasureSpot] = try LocalDataService.load("treasures")
            let zhNames: [String: ZhMapName] = try LocalDataService.load("zh-maps")
            let mapInfos: [String: MapInfo] = try LocalDataService.load("maps")
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
                    let name = zhNames[String(mapId)]?.zh ?? "未知地區 (\(mapId))"
                    return TreasureZone(mapId: mapId, name: name, spotCount: count)
                }
                .sorted { $0.mapId < $1.mapId }

                zonesByItemId[itemId] = zones
            }
        } catch {
            print("Failed to load treasure maps: \(error)")
        }
    }

    func zones(for map: TreasureMap) -> [TreasureZone] {
        zonesByItemId[map.itemId] ?? []
    }

    func spots(for map: TreasureMap, in zone: TreasureZone) -> [TreasureSpot] {
        spotsByKey["\(map.itemId)-\(zone.mapId)"] ?? []
    }

    func mapImageURL(for mapId: Int) -> String? {
        mapInfosByKey[String(mapId)]?.image
    }

    func gatheringNodes(for map: TreasureMap) -> [GatheringNodeDisplay] {
        var nodes: [GatheringNodeDisplay] = []
        for type in map.gatheringTypes {
            for zoneId in map.gatheringZoneIds {
                let zoneName = zoneNames[String(zoneId)]?.tw ?? "未知地區"
                nodes.append(GatheringNodeDisplay(type: type, zoneName: zoneName))
            }
        }
        return nodes
    }
}
