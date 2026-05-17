import Foundation

struct ItemDataResponse: Codable, Sendable {
    let items: [Item]
    let uiCategories: [UICategory]
    let classjobCategories: [ClassJobCategory]
    let equipSlots: [EquipSlot]

    enum CodingKeys: String, CodingKey {
        case items
        case uiCategories = "ui_categories"
        case classjobCategories = "classjob_categories"
        case equipSlots = "equip_slots"
    }

    init(
        items: [Item],
        uiCategories: [UICategory] = [],
        classjobCategories: [ClassJobCategory] = [],
        equipSlots: [EquipSlot] = []
    ) {
        self.items = items
        self.uiCategories = uiCategories
        self.classjobCategories = classjobCategories
        self.equipSlots = equipSlots
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        items = try container.decode([Item].self, forKey: .items)
        uiCategories = try container.decodeIfPresent([UICategory].self, forKey: .uiCategories) ?? []
        classjobCategories = try container.decodeIfPresent([ClassJobCategory].self, forKey: .classjobCategories) ?? []
        equipSlots = try container.decodeIfPresent([EquipSlot].self, forKey: .equipSlots) ?? []
    }
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
    let uiCategoryId: Int
    let classjobCategoryId: Int
    let equipSlot: Int

    enum CodingKeys: String, CodingKey {
        case id, ilvl, rarity
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case canBeHq = "can_be_hq"
        case isUntradable = "is_untradable"
        case uiCategoryId = "ui_category_id"
        case classjobCategoryId = "classjob_category_id"
        case equipSlot = "equip_slot"
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
        isUntradable: Bool,
        uiCategoryId: Int = 0,
        classjobCategoryId: Int = 0,
        equipSlot: Int = 0
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
        self.uiCategoryId = uiCategoryId
        self.classjobCategoryId = classjobCategoryId
        self.equipSlot = equipSlot
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
        uiCategoryId = try container.decodeIfPresent(Int.self, forKey: .uiCategoryId) ?? 0
        classjobCategoryId = try container.decodeIfPresent(Int.self, forKey: .classjobCategoryId) ?? 0
        equipSlot = try container.decodeIfPresent(Int.self, forKey: .equipSlot) ?? 0
    }

    var displayName: String {
        nameTw.isEmpty ? nameCn : nameTw
    }

    var iconURL: URL? {
        XIVIconURL.make(from: iconPath)
    }
}

struct UICategory: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let orderMinor: Int
    let orderMajor: Int

    enum CodingKeys: String, CodingKey {
        case id
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case orderMinor = "order_minor"
        case orderMajor = "order_major"
    }

    var displayName: String {
        nameTw.isEmpty ? nameCn : nameTw
    }
}

struct ClassJobCategory: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let jobs: [String]

    enum CodingKeys: String, CodingKey {
        case id, jobs
        case nameCn = "name_cn"
        case nameTw = "name_tw"
    }

    var displayName: String {
        nameTw.isEmpty ? nameCn : nameTw
    }
}

struct EquipSlot: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let nameTw: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameTw = "name_tw"
    }

    var displayName: String {
        nameTw
    }
}
