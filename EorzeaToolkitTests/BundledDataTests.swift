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

    func testTreasureMapDataDecodes() throws {
        let finalData: TreasureMapFinalData = try LocalDataService.load("treasure_maps_final")
        let spots: [TreasureSpot] = try LocalDataService.load("treasures")
        let zhNames = (try LocalDataService.load("zh-maps") as ZhMapNames).names
        let mapInfos: [String: MapInfo] = try LocalDataService.load("maps")

        XCTAssertFalse(finalData.maps.isEmpty)
        XCTAssertFalse(finalData.zoneNames.isEmpty)
        XCTAssertFalse(spots.isEmpty)
        XCTAssertFalse(zhNames.isEmpty)
        XCTAssertFalse(mapInfos.isEmpty)
    }

    /// Map names come from the item sheet and zone names from PlaceName. An empty name decodes
    /// fine and shows up as a blank row, so assert the names are really there.
    func testTreasureMapsHaveNamesAndNodes() throws {
        let data: TreasureMapFinalData = try LocalDataService.load("treasure_maps_final")

        XCTAssertFalse(data.maps.isEmpty)
        XCTAssertTrue(data.maps.allSatisfy { !$0.name.isEmpty }, "map with an empty name")
        XCTAssertTrue(data.maps.allSatisfy { !$0.gatheringNodes.isEmpty }, "map with no gathering nodes")
        XCTAssertFalse(data.zoneNames.isEmpty)
        XCTAssertTrue(data.zoneNames.values.allSatisfy { !$0.tw.isEmpty }, "zone with an empty name")
    }

    /// `TreasureMapViewModel` joins the four treasure files on map id, so a spot pointing at a
    /// map that no longer exists would drop out of the UI without any decode error.
    func testEveryTreasureSpotResolvesToAMap() throws {
        let spots: [TreasureSpot] = try LocalDataService.load("treasures")
        let mapInfos: [String: MapInfo] = try LocalDataService.load("maps")

        let unresolved = Set(spots.map(\.map)).subtracting(mapInfos.values.map(\.id))

        XCTAssertTrue(unresolved.isEmpty, "treasure spots reference unknown map ids: \(unresolved.sorted())")
    }

    /// The shop index is keyed by the item id rendered as a string. `ItemShopDataService` looks
    /// entries up with `String(itemID)`, so a key that is not a plain integer is unreachable.
    func testShopKeysAreItemIDsAsStrings() throws {
        let data: ItemShopDataResponse = try LocalDataService.load("item_shop")

        let malformed = data.shop.keys.filter { Int($0).map(String.init) != $0 }

        XCTAssertTrue(malformed.isEmpty, "unreachable shop keys: \(malformed.prefix(5))")
    }
}
