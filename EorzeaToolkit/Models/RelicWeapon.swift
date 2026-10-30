import Foundation

struct RelicWeaponData: Codable, Sendable {
    let weaponSeriesList: [WeaponSeries]

    enum CodingKeys: String, CodingKey {
        case weaponSeriesList = "weapon_series_list"
    }
}

struct WeaponSeries: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let nameTw: String
    let fullNameTw: String
    let expansion: String
    let levelCap: Int
    let availableJobs: [String]
    let stages: [WeaponStage]

    enum CodingKeys: String, CodingKey {
        case id, expansion, stages
        case nameTw = "name_tw"
        case fullNameTw = "full_name_tw"
        case levelCap = "level_cap"
        case availableJobs = "available_jobs"
    }
}

struct WeaponStage: Codable, Equatable, Identifiable, Sendable {
    var id: Int { stageIndex }

    let stageIndex: Int
    let nameTw: String
    let taskDescriptionTw: String
    let ilvl: Int?
    let materials: [WeaponMaterial]

    enum CodingKeys: String, CodingKey {
        case ilvl, materials
        case stageIndex = "stage_index"
        case nameTw = "name_tw"
        case taskDescriptionTw = "task_description_tw"
    }
}

enum MaterialQuantity: Codable, Equatable, Sendable {
    case none
    case number(Int)
    case text(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .none
        } else if let value = try? container.decode(Int.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .text(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "MaterialQuantity: expected Int, String, or null")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .none:
            try container.encodeNil()
        case .number(let value):
            try container.encode(value)
        case .text(let value):
            try container.encode(value)
        }
    }
}

struct WeaponMaterial: Codable, Equatable, Identifiable, Sendable {
    var id: String { "\(nameTw)-\(sourceTw ?? "")-\(quantity)" }

    let nameTw: String
    let quantity: MaterialQuantity
    let sourceTw: String?
    let noteTw: String?

    enum CodingKeys: String, CodingKey {
        case quantity
        case nameTw = "name_tw"
        case sourceTw = "source_tw"
        case noteTw = "note_tw"
    }
}
