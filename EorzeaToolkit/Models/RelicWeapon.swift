import Foundation

struct RelicWeaponData: Codable {
    let expansions: [Expansion]
}

struct Expansion: Codable, Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let weapons: [RelicWeapon]

    enum CodingKeys: String, CodingKey {
        case id, name, weapons
        case nameEn = "name_en"
    }
}

struct RelicWeapon: Codable, Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let job: String
    let steps: [RelicStep]

    enum CodingKeys: String, CodingKey {
        case id, name, job, steps
        case nameEn = "name_en"
    }
}

struct RelicStep: Codable, Identifiable {
    var id: Int { step }
    let step: Int
    let title: String
    let description: String
    let materials: [Material]
}

struct Material: Codable, Identifiable {
    var id: String { name }
    let name: String
    let quantity: Int
}
