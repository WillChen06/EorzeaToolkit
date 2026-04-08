import Foundation

// MARK: - 主要藏寶圖資料（treasure_maps.json）

struct TreasureMapData: Codable {
    let maps: [TreasureMap]
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

    enum CodingKeys: String, CodingKey {
        case id, grade, name, level, expansion, type
        case itemId = "item_id"
        case nameEn = "name_en"
        case nameJa = "name_ja"
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
