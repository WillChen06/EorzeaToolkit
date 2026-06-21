import Foundation

struct FishingDataResponse: Decodable, Sendable {
    let fishing: [String: [ItemFishingSpot]]
}

struct ItemFishingSpot: Decodable, Hashable, Sendable {
    let job: String
    let method: String
    let level: Int
    let stars: Int
    let zoneID: Int
    let zoneName: String
    let x: Double
    let y: Double
    let mapID: Int
    let isTimed: Bool
    let isWeathered: Bool
    let hasFolklore: Bool
    let teamcraftURL: String

    enum CodingKeys: String, CodingKey {
        case job, method, level, stars, x, y
        case zoneID = "zone_id"
        case zoneName = "zone_name"
        case mapID = "map_id"
        case isTimed = "is_timed"
        case isWeathered = "is_weathered"
        case hasFolklore = "has_folklore"
        case teamcraftURL = "teamcraft_url"
    }

    var locationText: String {
        let name = zoneName.isEmpty ? "未知地點" : zoneName
        return "\(name) (\(x.formattedCoordinate), \(y.formattedCoordinate))"
    }

    var levelText: String {
        let starText = String(repeating: "★", count: stars)

        if starText.isEmpty {
            return "Lv.\(level)"
        }

        return "Lv.\(level) \(starText)"
    }

    var teamcraftLinkURL: URL? {
        URL(string: teamcraftURL)
    }
}
