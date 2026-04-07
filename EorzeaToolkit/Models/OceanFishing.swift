import Foundation

struct OceanFishingData: Codable {
    let routes: [OceanFishingRoute]
}

struct OceanFishingRoute: Codable, Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let stops: [FishingStop]

    enum CodingKeys: String, CodingKey {
        case id, name, stops
        case nameEn = "name_en"
    }
}

struct FishingStop: Codable, Identifiable {
    var id: String { zone }
    let zone: String
    let zoneEn: String
    let fish: [FishInfo]

    enum CodingKeys: String, CodingKey {
        case zone, fish
        case zoneEn = "zone_en"
    }
}

struct FishInfo: Codable, Identifiable {
    var id: String { name }
    let name: String
    let nameEn: String
    let bait: String

    enum CodingKeys: String, CodingKey {
        case name, bait
        case nameEn = "name_en"
    }
}
