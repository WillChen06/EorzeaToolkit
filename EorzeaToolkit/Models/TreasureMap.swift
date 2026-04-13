import Foundation
import SwiftUI

// MARK: - 主要藏寶圖資料（treasure_maps_final.json）

struct TreasureMapFinalData: Codable {
    let maps: [TreasureMap]
    let zoneNames: [String: ZoneNameEntry]

    enum CodingKeys: String, CodingKey {
        case maps
        case zoneNames = "zone_names"
    }
}

struct ZoneNameEntry: Codable {
    let cn: String
    let tw: String
}

struct TreasureMap: Codable, Identifiable {
    let id: String
    let itemId: Int
    let grade: String
    let name: String
    let nameEn: String
    let nameJa: String
    let level: Int
    let expansion: String
    let type: MapType
    let gatheringTypes: [Int]
    let gatheringZoneIds: [Int]

    enum CodingKeys: String, CodingKey {
        case id, grade, level, expansion, type
        case itemId = "item_id"
        case name = "name_tw"
        case nameEn = "name_en"
        case nameJa = "name_ja"
        case gatheringTypes = "gathering_types"
        case gatheringZoneIds = "gathering_zone_ids"
    }

    enum MapType: String, Codable {
        case solo
        case party

        var label: String {
            switch self {
            case .solo: return "單人"
            case .party: return "8人"
            }
        }
    }
}

// MARK: - 採集點顯示用

enum GatheringJob: String {
    case miner
    case botanist

    var label: String {
        switch self {
        case .miner: return "採掘師"
        case .botanist: return "園藝師"
        }
    }
}

struct GatheringNodeDisplay: Identifiable {
    let id = UUID()
    let type: Int
    let zoneName: String

    var job: GatheringJob {
        type <= 1 ? .miner : .botanist
    }

    var typeName: String {
        switch type {
        case 0: return "礦脈"
        case 1: return "石場"
        case 2: return "良材"
        case 3: return "草叢"
        default: return "未知"
        }
    }

    var typeColor: Color {
        switch type {
        case 0: return .orange
        case 1: return .gray
        case 2: return .green
        case 3: return Color(.sRGB, red: 0.6, green: 0.75, blue: 0.2)
        default: return .white
        }
    }
}

// MARK: - 寶藏點位資料（treasures.json）

struct TreasureSpot: Codable {
    let id: String
    let coords: Coordinate
    let map: Int
    let partySize: Int
    let item: Int

    struct Coordinate: Codable {
        let x: Double
        let y: Double
        let z: Double
    }
}

// MARK: - 地圖資訊（maps.json）

struct MapInfo: Codable {
    let id: Int
    let image: String
    let placenameId: Int
    let sizeFactor: Int
    let territoryId: Int
    let dungeon: Bool

    enum CodingKeys: String, CodingKey {
        case id, image, dungeon
        case placenameId = "placename_id"
        case sizeFactor = "size_factor"
        case territoryId = "territory_id"
    }
}

// MARK: - 地圖中文名稱（zh-maps.json）

struct ZhMapName: Codable {
    let zh: String
}

// MARK: - 組合後的地區資訊

struct TreasureZone: Identifiable {
    let mapId: Int
    let name: String
    let spotCount: Int

    var id: Int { mapId }
}
