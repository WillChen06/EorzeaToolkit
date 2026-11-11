import Testing
@testable import EorzeaToolkit

/// `ItemCatalog` holds what the item search reads from the loaded data.
struct ItemCatalogTests {
    @Test func itemsKeepTheirOrderAndCanBeLookedUpByID() {
        let catalog = ItemCatalog(data: ItemDataResponse(
            meta: ItemDataMeta(version: "2026.09.14.0000.0000-r5"),
            items: [item(id: 30, name: "白鋼錠"), item(id: 10, name: "奶油"), item(id: 20, name: "白魔長袍")]
        ))

        #expect(catalog.items.map(\.id) == [30, 10, 20])
        #expect(catalog.itemsByID[10]?.nameTw == "奶油")
        #expect(catalog.itemsByID[20]?.nameTw == "白魔長袍")
        #expect(catalog.itemsByID[99] == nil)
        #expect(catalog.version == "2026.09.14.0000.0000-r5")
    }

    @Test func dataWithoutMetaHasNoVersion() {
        let catalog = ItemCatalog(data: ItemDataResponse(items: []))

        #expect(catalog.version == nil)
    }

    /// Slot 0 means the item cannot be equipped; the filter never offers it.
    @Test func equipSlotZeroIsLeftOut() {
        let catalog = ItemCatalog(data: ItemDataResponse(
            items: [],
            equipSlots: [
                EquipSlot(id: 0, nameTw: ""),
                EquipSlot(id: 1, nameTw: "主手"),
                EquipSlot(id: 13, nameTw: "主手（無法裝備副手）"),
                EquipSlot(id: 4, nameTw: "身體")
            ]
        ))

        #expect(catalog.equipSlots.map(\.id) == [1, 13, 4])
        #expect(catalog.baseEquipSlots.map(\.id) == [1, 4])
        #expect(catalog.restrictedEquipSlots.map(\.id) == [13])
    }

    @Test func eachJobCategoryBecomesASetOfJobs() {
        let catalog = ItemCatalog(data: ItemDataResponse(
            items: [],
            classjobCategories: [
                ClassJobCategory(id: 2, nameTw: "劍術士", jobs: ["GLA"]),
                ClassJobCategory(id: 38, nameTw: "劍術士 騎士", jobs: ["GLA", "PLD"])
            ]
        ))

        #expect(catalog.classjobJobSetsById == [2: ["GLA"], 38: ["GLA", "PLD"]])
    }

    private func item(id: Int, name: String) -> Item {
        Item(
            id: id,
            nameTw: name,
            iconId: 0,
            iconPath: "",
            ilvl: 1,
            rarity: 1,
            canBeHq: false,
            isUntradable: false
        )
    }
}
