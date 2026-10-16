import Foundation

/// Words players use that the item data has no name for, matched like any other name.
///
/// They were added after the first held-out run, where most misses were sentences such as
/// 「坦用的武器」 (prompts/item-description-search.md, 「比對規則調整」). The matcher keeps only the
/// targets the data and the job filter have, and a longer name still wins over a word inside it.
enum ItemQueryEverydayNames {
    struct Group: Sendable {
        let names: [String]
        let targets: [String]
    }

    struct RarityWeapon: Sendable {
        let name: String
        let rarity: String
    }

    /// Either hand. A weapon is in either hand, so 武器 also covers a paladin's shield.
    static let weaponSlots = ["主手", "副手"]

    /// Job roles, by the item search filter's job abbreviations.
    static let jobGroups: [Group] = [
        Group(names: ["坦", "坦克"], targets: ["PLD", "WAR", "DRK", "GNB"]),
        Group(names: ["補", "補師", "治療"], targets: ["WHM", "SCH", "AST", "SGE"]),
        Group(names: ["近戰"], targets: ["MNK", "DRG", "NIN", "SAM", "RPR", "VPR"]),
        Group(names: ["遠敏", "遠程物理"], targets: ["BRD", "MCH", "DNC"]),
        Group(names: ["法系", "遠程魔法"], targets: ["BLM", "SMN", "RDM", "PCT"]),
        Group(names: ["採集職", "大地使者"], targets: ["MIN", "BTN", "FSH"]),
        Group(names: ["生產職", "能工巧匠"], targets: ["CRP", "BSM", "ARM", "GSM", "LTW", "WVR", "ALC", "CUL"])
    ]

    /// Body parts, by their names in the item data.
    static let slots: [Group] = [
        Group(names: ["頭", "帽子"], targets: ["頭部"]),
        Group(names: ["衣服", "上衣"], targets: ["身體"]),
        Group(names: ["手套"], targets: ["手部"]),
        Group(names: ["褲子"], targets: ["腿部"]),
        Group(names: ["鞋子", "鞋", "靴子"], targets: ["腳部"]),
        Group(names: ["耳環"], targets: ["耳部"]),
        Group(names: ["手環"], targets: ["腕部"]),
        Group(names: ["武器"], targets: weaponSlots)
    ]

    /// Categories, by their names in the item data. A word for several is narrowed to the jobs
    /// in the sentence, as 副工具 is: 白魔的杖 is a conjurer's staff.
    static let categories: [Group] = [
        Group(names: ["杖"], targets: ["單手幻杖", "雙手幻杖", "單手咒杖", "雙手咒杖", "青魔杖"]),
        Group(names: ["雙手杖"], targets: ["雙手幻杖", "雙手咒杖"]),
        Group(names: ["單手杖"], targets: ["單手幻杖", "單手咒杖"]),
        Group(names: ["刀"], targets: ["武士刀", "二刀流武器"]),
        Group(names: ["二刀"], targets: ["二刀流武器"]),
        Group(names: ["槍"], targets: ["長槍", "火槍", "槍刃"]),
        Group(names: ["食物", "料理"], targets: ["食品"]),
        Group(names: ["染劑"], targets: ["染料"])
    ]

    /// A rarity's colour and 武, for a weapon of that rarity in either hand, as 武器 is.
    static let rarityWeapons: [RarityWeapon] = [
        RarityWeapon(name: "紫武", rarity: "武勳")
    ]
}
