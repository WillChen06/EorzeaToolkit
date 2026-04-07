import Foundation

struct TreasureMapData: Codable {
    let maps: [TreasureMap]
}

struct TreasureMap: Codable, Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let nameJa: String
    let level: Int
    let locations: [TreasureMapLocation]

    enum CodingKeys: String, CodingKey {
        case id, name, level, locations
        case nameEn = "name_en"
        case nameJa = "name_ja"
    }
}

struct TreasureMapLocation: Codable, Identifiable {
    var id: String { "\(zone)-\(coordinates.x)-\(coordinates.y)" }
    let zone: String
    let zoneEn: String
    let coordinates: Coordinates
    let notes: String

    enum CodingKeys: String, CodingKey {
        case zone, coordinates, notes
        case zoneEn = "zone_en"
    }
}

struct Coordinates: Codable {
    let x: Double
    let y: Double
}
