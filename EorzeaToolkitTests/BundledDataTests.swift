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

    func testRelicWeaponsDecode() throws {
        let data: RelicWeaponData = try LocalDataService.load("relic_weapons")

        XCTAssertFalse(data.weaponSeriesList.isEmpty)
        XCTAssertTrue(data.weaponSeriesList.allSatisfy { !$0.stages.isEmpty }, "series with no stages")
    }

    func testTreasureMapDataDecodes() throws {
        let finalData: TreasureMapFinalData = try LocalDataService.load("treasure_maps_final")
        let spots: [TreasureSpot] = try LocalDataService.load("treasures")
        let zhNames: [String: ZhMapName] = try LocalDataService.load("zh-maps")
        let mapInfos: [String: MapInfo] = try LocalDataService.load("maps")

        XCTAssertFalse(finalData.maps.isEmpty)
        XCTAssertFalse(finalData.zoneNames.isEmpty)
        XCTAssertFalse(spots.isEmpty)
        XCTAssertFalse(zhNames.isEmpty)
        XCTAssertFalse(mapInfos.isEmpty)
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
