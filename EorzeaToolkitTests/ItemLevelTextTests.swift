import XCTest
@testable import EorzeaToolkit

/// The level text in the search results and on the detail page. The checks look for the numbers
/// rather than a whole literal, so they pass in any language.
final class ItemLevelTextTests: XCTestCase {
    func testEquipmentShowsItsEquipLevelBeforeItsItemLevel() throws {
        let text = L10n.ItemSearch.levelText(for: item(equipSlot: 1, equipLevel: 100, itemLevel: 700))

        let equipLevel = try XCTUnwrap(text.range(of: "100"), text)
        let itemLevel = try XCTUnwrap(text.range(of: "700"), text)
        XCTAssertLessThan(equipLevel.lowerBound, itemLevel.lowerBound, text)
        XCTAssertNotEqual(text, L10n.ItemSearch.levelText(for: item(equipSlot: 0, equipLevel: 100, itemLevel: 700)))
    }

    /// Bait's value is the level needed to use it, not an equip level.
    func testItemsThatCannotBeEquippedShowOnlyTheirItemLevel() {
        let bait = item(equipSlot: 0, equipLevel: 80, itemLevel: 430)
        let text = L10n.ItemSearch.levelText(for: bait)

        XCTAssertTrue(text.contains("430"), text)
        XCTAssertFalse(text.contains("80"), text)
    }

    func testEquipmentWithoutAnEquipLevelShowsOnlyItsItemLevel() {
        let text = L10n.ItemSearch.levelText(for: item(equipSlot: 1, equipLevel: 0, itemLevel: 430))

        XCTAssertEqual(text, L10n.ItemSearch.levelText(for: item(equipSlot: 0, equipLevel: 0, itemLevel: 430)))
    }

    func testOnlyEquipmentHasAnEquipmentLevel() {
        XCTAssertEqual(item(equipSlot: 1, equipLevel: 100, itemLevel: 700).equipmentLevel, 100)
        XCTAssertNil(item(equipSlot: 0, equipLevel: 80, itemLevel: 430).equipmentLevel)
        XCTAssertNil(item(equipSlot: 1, equipLevel: 0, itemLevel: 430).equipmentLevel)
    }

    private func item(equipSlot: Int, equipLevel: Int, itemLevel: Int) -> Item {
        Item(
            id: 1,
            nameTw: "測試道具",
            iconId: 0,
            iconPath: "",
            ilvl: itemLevel,
            rarity: 1,
            canBeHq: false,
            isUntradable: false,
            equipSlot: equipSlot,
            equipLevel: equipLevel
        )
    }
}
