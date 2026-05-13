import Foundation

struct RelicWeaponData: Codable {
    let weaponSeries: WeaponSeries

    enum CodingKeys: String, CodingKey {
        case weaponSeries = "weapon_series"
    }
}

struct WeaponSeries: Codable, Identifiable {
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

struct WeaponStage: Codable, Identifiable {
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

enum MaterialQuantity: Codable, Equatable {
    case number(Int)
    case text(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Int.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .text(value)
        } else {
            self = .text("?")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .number(let value):
            try container.encode(value)
        case .text(let value):
            try container.encode(value)
        }
    }
}

struct WeaponMaterial: Codable, Identifiable {
    var id: String { "\(nameTw)-\(quantity)" }

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
