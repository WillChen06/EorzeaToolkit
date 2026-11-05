import XCTest
@testable import EorzeaToolkit

/// Every bundled JSON file is decoded through the type the app actually loads it with.
///
/// The models declare most of their fields non-optional, so a missing or retyped field throws
/// at decode time. In the app that surfaces as a logged error and an empty screen — release
/// builds have no assertion to trip — which makes a hand-edited or truncated data file one of
/// the quieter ways to break a feature. Asserting against the real model types rather than a
/// schema written out separately means these checks cannot drift away from the code they guard.
final class BundledDataTests: XCTestCase {
    func testItemsDecode() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")

        XCTAssertFalse(data.items.isEmpty)
        XCTAssertEqual(Set(data.items.map(\.id)).count, data.items.count, "duplicate item ids")
    }

    /// The lookup tables decode as empty when their key is missing or renamed, which hides the
    /// category, job and equip slot filters instead of failing. Assert they are really there.
    func testItemFilterTablesDecode() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")

        XCTAssertFalse(data.uiCategories.isEmpty, "ui_categories")
        XCTAssertFalse(data.classjobCategories.isEmpty, "classjob_categories")
        XCTAssertFalse(data.equipSlots.isEmpty, "equip_slots")
    }

    /// An item's equip level decodes as 0 when `equip_level` is missing or renamed, which would
    /// leave the equip level filter with no results instead of failing. Every item has one.
    func testItemEquipLevelsDecode() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")
        let withoutLevel = data.items.filter { $0.equipLevel < 1 }.map(\.id)

        XCTAssertTrue(withoutLevel.isEmpty, "items without an equip level: \(withoutLevel.prefix(5))")
    }

    /// The loader compares this version with the cache and the remote manifest. If it did not
    /// parse, any downloaded or cached copy would count as newer than the bundled data.
    func testItemsVersionParses() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")
        let version = try XCTUnwrap(data.version, "items.json has no _meta.version")

        XCTAssertNotNil(ItemDataVersion(version), version)
    }

    func testRecipesDecode() throws {
        let data: RecipeDataResponse = try LocalDataService.load("recipes")

        XCTAssertFalse(data.recipes.isEmpty)
        XCTAssertTrue(data.recipes.values.allSatisfy { !$0.isEmpty }, "item mapped to no recipes")
    }

    func testGatheringDecodes() throws {
        let data: GatheringDataResponse = try LocalDataService.load("gathering")

        XCTAssertFalse(data.gathering.isEmpty)
        XCTAssertTrue(data.gathering.values.allSatisfy { !$0.isEmpty }, "item mapped to no nodes")
    }

    func testFishingDecodes() throws {
        let data: FishingDataResponse = try LocalDataService.load("fishing")

        XCTAssertFalse(data.fishing.isEmpty)
        XCTAssertTrue(data.fishing.values.allSatisfy { !$0.isEmpty }, "item mapped to no spots")
    }

    func testItemShopDecodes() throws {
        let data: ItemShopDataResponse = try LocalDataService.load("item_shop")

        XCTAssertFalse(data.shop.isEmpty)
    }

    func testBattleActionsDecode() throws {
        let data: BattleActionsData = try LocalDataService.load("battle_actions")

        XCTAssertFalse(data.jobs.isEmpty)
        XCTAssertFalse(data.tinctures.isEmpty)
    }

    /// The rotation editor shows the description for the selected level, and every action is
    /// learned by the level cap, so each one needs a description there. The keys are levels
    /// written as strings, which decode into `[Int: String]` only when every one is a number.
    func testBattleActionsHaveADescriptionAtTheLevelCap() throws {
        let data: BattleActionsData = try LocalDataService.load("battle_actions")
        let level = SkillRotationLevel.level100.rawValue

        let missing = data.jobs.flatMap { job in
            job.actions
                .filter { ($0.description(at: level) ?? "").isEmpty }
                .map { "\(job.abbreviation) \($0.id)" }
        }

        XCTAssertTrue(missing.isEmpty, "actions without a Lv\(level) description: \(missing.prefix(5))")
    }

    func testRelicWeaponsDecode() throws {
        let data: RelicWeaponData = try LocalDataService.load("relic_weapons")

        XCTAssertFalse(data.weaponSeriesList.isEmpty)
        XCTAssertTrue(data.weaponSeriesList.allSatisfy { !$0.stages.isEmpty }, "series with no stages")
    }

    /// The treasure map feature reads only this file, through the same type the client decodes.
    func testTreasureMapDataDecodes() throws {
        let data: TreasureMapData = try LocalDataService.load("treasure_maps")
        let zones = data.maps.flatMap(\.zones)

        XCTAssertFalse(data.maps.isEmpty)
        XCTAssertTrue(data.maps.allSatisfy { !$0.zones.isEmpty }, "map with no zones")
        XCTAssertTrue(zones.allSatisfy { !$0.spots.isEmpty }, "zone with no spots")
        XCTAssertTrue(data.maps.allSatisfy { !$0.gatheringNodes.isEmpty }, "map with no gathering nodes")
    }

    /// Names come from the item and PlaceName sheets, and images from the Map sheet. An empty
    /// value decodes fine and shows up as a blank row or an empty map, so assert they are there.
    func testTreasureMapsHaveNamesAndImages() throws {
        let data: TreasureMapData = try LocalDataService.load("treasure_maps")
        let zones = data.maps.flatMap(\.zones)
        let nodes = data.maps.flatMap(\.gatheringNodes)

        XCTAssertTrue(data.maps.allSatisfy { !$0.name.isEmpty }, "map with an empty name")
        XCTAssertTrue(zones.allSatisfy { !$0.name.isEmpty && URL(string: $0.image) != nil }, "zone without a name or image")
        XCTAssertTrue(nodes.allSatisfy { !$0.zoneName.isEmpty && URL(string: $0.image) != nil }, "node without a name or image")
    }

    /// The spot card shows the map's party size: 1 for solo maps and 8 for party maps.
    func testTreasureMapPartySizesMatchTheirType() throws {
        let data: TreasureMapData = try LocalDataService.load("treasure_maps")

        let mismatched = data.maps.filter { $0.maxPartySize != ($0.type == .solo ? 1 : 8) }

        XCTAssertTrue(mismatched.isEmpty, "maps whose party size does not match their type: \(mismatched.map(\.grade))")
    }

    /// The shop index is keyed by the item id rendered as a string. `ItemShopDataService` looks
    /// entries up with `String(itemID)`, so a key that is not a plain integer is unreachable.
    func testShopKeysAreItemIDsAsStrings() throws {
        let data: ItemShopDataResponse = try LocalDataService.load("item_shop")

        let malformed = data.shop.keys.filter { Int($0).map(String.init) != $0 }

        XCTAssertTrue(malformed.isEmpty, "unreachable shop keys: \(malformed.prefix(5))")
    }
}
