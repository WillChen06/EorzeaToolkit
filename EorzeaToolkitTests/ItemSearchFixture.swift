//
//  ItemSearchFixture.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/12.
//

@testable import EorzeaToolkit

enum ItemSearchFixture {
    /// Class job category ids.
    static let whiteMage = 1
    static let blackMage = 2

    /// The items of `ItemSearchFilterOnlyTests`. Their names cover each name search rank
    /// (whole name, prefix, contained), and the two 600 robes differ only in a Latin letter,
    /// which sorts the same in every locale.
    static let items = [
        item(id: 1, name: "白魔長袍B", ilvl: 600, job: whiteMage),
        item(id: 2, name: "白魔長袍A", ilvl: 600, job: whiteMage),
        item(id: 3, name: "白魔頭冠", ilvl: 700, job: whiteMage),
        item(id: 4, name: "黑魔長袍", ilvl: 650, job: blackMage),
        item(id: 5, name: "藥水", ilvl: 1)
    ]

    static let classjobCategories = [
        ClassJobCategory(id: whiteMage, nameTw: "白魔道士", jobs: ["WHM"]),
        ClassJobCategory(id: blackMage, nameTw: "黑魔道士", jobs: ["BLM"])
    ]

    static func item(
        id: Int,
        name: String,
        ilvl: Int = 1,
        rarity: Int = 1,
        job: Int = 0,
        equipSlot: Int = 0,
        equipLevel: Int = 0,
        canBeHq: Bool = false,
        isUntradable: Bool = false
    ) -> Item {
        Item(
            id: id,
            nameTw: name,
            iconId: 0,
            iconPath: "",
            ilvl: ilvl,
            rarity: rarity,
            canBeHq: canBeHq,
            isUntradable: isUntradable,
            classjobCategoryId: job,
            equipSlot: equipSlot,
            equipLevel: equipLevel
        )
    }

    static func catalog(
        items: [Item] = ItemSearchFixture.items,
        version: String? = "v1",
        classjobCategories: [ClassJobCategory] = ItemSearchFixture.classjobCategories,
        equipSlots: [EquipSlot] = []
    ) -> ItemCatalog {
        ItemCatalog(data: ItemDataResponse(
            meta: ItemDataMeta(version: version),
            items: items,
            classjobCategories: classjobCategories,
            equipSlots: equipSlots
        ))
    }
}
