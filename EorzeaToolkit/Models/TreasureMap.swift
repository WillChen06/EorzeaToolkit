import Foundation
import SwiftUI

// MARK: - 藏寶圖資料（treasure_maps.json）

struct TreasureMapData: Decodable {
    let maps: [TreasureMap]
}

struct TreasureMap: Codable, Identifiable, Equatable {
    let id: String
    let itemId: Int
    let grade: String
    let name: String
    let level: Int
    let expansion: String
    let type: MapType
    let maxPartySize: Int
    let gatheringTypes: [Int]
    let gatheringZoneIds: [Int]
    /// The maps the treasure spots are on, sorted by map id.
    let zones: [TreasureZone]
    let gatheringNodes: [GatheringNode]

    enum CodingKeys: String, CodingKey {
        case id, grade, level, expansion, type, zones
        case itemId = "item_id"
        case name = "name_tw"
        case maxPartySize = "max_party_size"
        case gatheringTypes = "gathering_types"
        case gatheringZoneIds = "gathering_zone_ids"
        case gatheringNodes = "gathering_nodes"
    }

    enum MapType: String, Codable {
        case solo
        case party

        var label: String {
            switch self {
            case .solo: return L10n.TreasureMap.MapType.soloText
            case .party: return L10n.TreasureMap.MapType.partyText
            }
        }
    }

    var gradeNumber: Int? {
        guard grade.first == "G" else {
            return nil
        }

        return Int(grade.dropFirst())
    }

    var expansionMajorVersion: Int? {
        guard let majorComponent = expansion.split(separator: ".", omittingEmptySubsequences: false).first else {
            return nil
        }

        return Int(majorComponent)
    }
}

// MARK: - 地區與寶藏點

/// A map that treasure spots are on, with what the spot cards need to draw it.
struct TreasureZone: Codable, Identifiable, Equatable {
    let mapId: Int
    let name: String
    let image: String
    let sizeFactor: Int
    let spots: [TreasureSpot]

    var id: Int { mapId }

    enum CodingKeys: String, CodingKey {
        case image, spots
        case mapId = "map_id"
        case name = "name_tw"
        case sizeFactor = "size_factor"
    }
}

struct TreasureSpot: Codable, Identifiable, Equatable {
    /// The `TreasureSpot` sheet key, for example `"1.0"`.
    let id: String
    let x: Double
    let y: Double
}

// MARK: - 採集點

enum GatheringJob: String, Codable {
    case miner
    case botanist

    var label: String {
        switch self {
        case .miner: return L10n.TreasureMap.GatheringJob.minerText
        case .botanist: return L10n.TreasureMap.GatheringJob.botanistText
        }
    }
}

struct GatheringNode: Codable, Identifiable, Equatable {
    var id: String { "\(mapId)-\(type)-\(x)-\(y)" }
    let type: Int
    let job: GatheringJob
    let zoneId: Int
    /// The map the node is on. Several maps can share one zone (PlaceName), so open this one.
    let mapId: Int
    let x: Double
    let y: Double
    let zoneName: String
    /// The image of the map the node is on.
    let image: String
    let sizeFactor: Int

    enum CodingKeys: String, CodingKey {
        case type, job, x, y, image
        case zoneId = "zone_id"
        case mapId = "map_id"
        case zoneName = "zone_name_tw"
        case sizeFactor = "size_factor"
    }

    var typeName: String {
        switch type {
        case 0: return L10n.TreasureMap.GatheringNode.mineralDepositText
        case 1: return L10n.TreasureMap.GatheringNode.rockyOutcropText
        case 2: return L10n.TreasureMap.GatheringNode.matureTreeText
        case 3: return L10n.TreasureMap.GatheringNode.lushVegetationText
        default: return L10n.TreasureMap.GatheringNode.unknownText
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

    var typeIconURL: URL? {
        let path: String
        switch type {
        case 0: path = "https://xivapi.com/i/060000/060438.png"  // 礦脈
        case 1: path = "https://xivapi.com/i/060000/060437.png"  // 石場
        case 2: path = "https://xivapi.com/i/060000/060433.png"  // 良材
        case 3: path = "https://xivapi.com/i/060000/060432.png"  // 草叢
        default: return nil
        }
        return URL(string: path)
    }
}
