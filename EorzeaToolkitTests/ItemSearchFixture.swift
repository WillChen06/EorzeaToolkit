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
        uiCategory: Int = 0,
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
            uiCategoryId: uiCategory,
            classjobCategoryId: job,
            equipSlot: equipSlot,
            equipLevel: equipLevel
        )
    }

    static func catalog(
        items: [Item] = ItemSearchFixture.items,
        version: String? = "v1",
        uiCategories: [UICategory] = [],
        classjobCategories: [ClassJobCategory] = ItemSearchFixture.classjobCategories,
        equipSlots: [EquipSlot] = []
    ) -> ItemCatalog {
        ItemCatalog(data: ItemDataResponse(
            meta: ItemDataMeta(version: version),
            items: items,
            uiCategories: uiCategories,
            classjobCategories: classjobCategories,
            equipSlots: equipSlots
        ))
    }

    // MARK: - Filtering

    /// UI category and equip slot ids.
    static let shield = 11
    static let bodyArmor = 34
    static let offHand = 2
    static let body = 4

    /// Two items that differ in everything the filter compares, so each filter keeps exactly one.
    static let filterItems = [
        item(
            id: 1, name: "木盾", ilvl: 100, rarity: 1, uiCategory: shield, job: whiteMage,
            equipSlot: offHand, equipLevel: 50, canBeHq: false, isUntradable: true
        ),
        item(
            id: 2, name: "棉布長袍", ilvl: 600, rarity: 3, uiCategory: bodyArmor, job: blackMage,
            equipSlot: body, equipLevel: 90, canBeHq: true, isUntradable: false
        )
    ]

    static func filterCatalog() -> ItemCatalog {
        catalog(
            items: filterItems,
            uiCategories: [
                UICategory(id: shield, nameTw: "盾", orderMinor: 1, orderMajor: 1),
                UICategory(id: bodyArmor, nameTw: "身體防具", orderMinor: 1, orderMajor: 3)
            ],
            equipSlots: [EquipSlot(id: offHand, nameTw: "副手"), EquipSlot(id: body, nameTw: "身體")]
        )
    }
}
