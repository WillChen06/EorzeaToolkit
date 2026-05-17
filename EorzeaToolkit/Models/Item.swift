import Foundation

struct ItemDataResponse: Codable, Sendable {
    let items: [Item]
}

struct Item: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let iconId: Int
    let iconPath: String
    let ilvl: Int
    let rarity: Int
    let canBeHq: Bool
    let isUntradable: Bool

    enum CodingKeys: String, CodingKey {
        case id, ilvl, rarity
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case canBeHq = "can_be_hq"
        case isUntradable = "is_untradable"
    }

    init(
        id: Int,
        nameCn: String,
        nameTw: String,
        iconId: Int,
        iconPath: String,
        ilvl: Int,
        rarity: Int,
        canBeHq: Bool,
        isUntradable: Bool
    ) {
        self.id = id
        self.nameCn = nameCn
        self.nameTw = nameTw
        self.iconId = iconId
        self.iconPath = iconPath
        self.ilvl = ilvl
        self.rarity = rarity
        self.canBeHq = canBeHq
        self.isUntradable = isUntradable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        nameCn = try container.decode(String.self, forKey: .nameCn)
        nameTw = try container.decode(String.self, forKey: .nameTw)
        iconId = try container.decode(Int.self, forKey: .iconId)
        iconPath = try container.decode(String.self, forKey: .iconPath)
        ilvl = try container.decode(Int.self, forKey: .ilvl)
        rarity = try container.decode(Int.self, forKey: .rarity)
        canBeHq = try container.decodeIfPresent(Bool.self, forKey: .canBeHq) ?? false
        isUntradable = try container.decodeIfPresent(Bool.self, forKey: .isUntradable) ?? false
    }

    var displayName: String {
        nameTw.isEmpty ? nameCn : nameTw
    }

    var iconURL: URL? {
        XIVIconURL.make(from: iconPath)
    }
}
