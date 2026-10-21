import Foundation

struct ItemDataResponse: Codable, Sendable {
    let meta: ItemDataMeta?
    let items: [Item]
    let uiCategories: [UICategory]
    let classjobCategories: [ClassJobCategory]
    let equipSlots: [EquipSlot]

    enum CodingKeys: String, CodingKey {
        case meta = "_meta"
        case items
        case uiCategories = "ui_categories"
        case classjobCategories = "classjob_categories"
        case equipSlots = "equip_slots"
    }

    init(
        meta: ItemDataMeta? = nil,
        items: [Item],
        uiCategories: [UICategory] = [],
        classjobCategories: [ClassJobCategory] = [],
        equipSlots: [EquipSlot] = []
    ) {
        self.meta = meta
        self.items = items
        self.uiCategories = uiCategories
        self.classjobCategories = classjobCategories
        self.equipSlots = equipSlots
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // `_meta` only documents the file; a shape this model does not expect must not make
        // the items themselves unreadable.
        meta = try? container.decodeIfPresent(ItemDataMeta.self, forKey: .meta)
        items = try container.decode([Item].self, forKey: .items)
        uiCategories = try container.decodeIfPresent([UICategory].self, forKey: .uiCategories) ?? []
        classjobCategories = try container.decodeIfPresent([ClassJobCategory].self, forKey: .classjobCategories) ?? []
        equipSlots = try container.decodeIfPresent([EquipSlot].self, forKey: .equipSlots) ?? []
    }

    /// `_meta.version`, see `ItemDataVersion`. Files from before the Traditional Chinese data
    /// have none.
    var version: String? {
        meta?.version
    }
}

/// The part of `items.json`'s `_meta` the app reads. The other fields document the file.
struct ItemDataMeta: Codable, Sendable {
    let version: String?
}

struct Item: Codable, Identifiable, Hashable, Sendable {
    let id: Int
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
    /// The level needed to equip or use the item, not its item level. 0 when the data has none.
    let equipLevel: Int

    enum CodingKeys: String, CodingKey {
        case id, ilvl, rarity
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case canBeHq = "can_be_hq"
        case isUntradable = "is_untradable"
        case uiCategoryId = "ui_category_id"
        case classjobCategoryId = "classjob_category_id"
        case equipSlot = "equip_slot"
        case equipLevel = "equip_level"
    }

    init(
        id: Int,
        nameTw: String,
        iconId: Int,
        iconPath: String,
        ilvl: Int,
        rarity: Int,
        canBeHq: Bool,
        isUntradable: Bool,
        uiCategoryId: Int = 0,
        classjobCategoryId: Int = 0,
        equipSlot: Int = 0,
        equipLevel: Int = 0
    ) {
        self.id = id
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
        self.equipLevel = equipLevel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
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
        equipLevel = try container.decodeIfPresent(Int.self, forKey: .equipLevel) ?? 0
    }

    var displayName: String {
        nameTw
    }

    /// The equip level of an item that can be equipped, or nil. Other items have a value in the
    /// data too, but it is not an equip level: bait stores the level needed to use it.
    var equipmentLevel: Int? {
        equipSlot != 0 && equipLevel > 0 ? equipLevel : nil
    }

    var iconURL: URL? {
        XIVIconURL.make(from: iconPath)
    }
}

struct UICategory: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let nameTw: String
    let orderMinor: Int
    let orderMajor: Int

    enum CodingKeys: String, CodingKey {
        case id
        case nameTw = "name_tw"
        case orderMinor = "order_minor"
        case orderMajor = "order_major"
    }

    var displayName: String {
        nameTw
    }
}

struct ClassJobCategory: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let nameTw: String
    let jobs: [String]

    enum CodingKeys: String, CodingKey {
        case id, jobs
        case nameTw = "name_tw"
    }

    var displayName: String {
        nameTw
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

    /// The slot a restricted variant belongs to: 「身體」 for 「身體（無法裝備頭部）」.
    var baseName: String {
        nameParts.base
    }

    /// What a variant keeps from being equipped: 「無法裝備頭部」 for 「身體（無法裝備頭部）」.
    var restriction: String? {
        nameParts.restriction
    }

    private var nameParts: (base: String, restriction: String?) {
        guard nameTw.hasSuffix("）"), let open = nameTw.firstIndex(of: "（") else {
            return (nameTw, nil)
        }
        let restriction = nameTw[nameTw.index(after: open)..<nameTw.index(before: nameTw.endIndex)]
        return (String(nameTw[..<open]), restriction.isEmpty ? nil : String(restriction))
    }

    /// Splits slots into the plain ones, in their given order, and the restricted variants, grouped
    /// in the order of their plain slots and by id within each group.
    static func filterSections(_ slots: [EquipSlot]) -> (base: [EquipSlot], restricted: [EquipSlot]) {
        let base = slots.filter { $0.restriction == nil }
        let baseOrder = Dictionary(
            base.enumerated().map { ($0.element.baseName, $0.offset) },
            uniquingKeysWith: { first, _ in first }
        )
        let restricted = slots
            .filter { $0.restriction != nil }
            .sorted { lhs, rhs in
                let lhsOrder = baseOrder[lhs.baseName] ?? Int.max
                let rhsOrder = baseOrder[rhs.baseName] ?? Int.max
                return lhsOrder == rhsOrder ? lhs.id < rhs.id : lhsOrder < rhsOrder
            }
        return (base, restricted)
    }
}
