import XCTest
@testable import EorzeaToolkit

/// `price_mid` and `in_gil_shop` are independent, and every combination of them occurs in
/// the real `item_shop.json`. The distinction that matters is that a price on its own is
/// what an NPC pays the player, not what the player pays a shop — only `in_gil_shop` makes
/// an entry a shop purchase. Getting this backwards would show buy prices for items no
/// shop sells.
final class ItemShopEntryTests: XCTestCase {
    private func entry(from json: String) throws -> ItemShopEntry {
        try JSONDecoder().decode(ItemShopEntry.self, from: Data(json.utf8))
    }

    func testPriceWithShopFlagIsAShopPurchase() throws {
        let entry = try entry(from: #"{"price_mid": 63, "in_gil_shop": true}"#)

        XCTAssertEqual(entry.priceMid, 63)
        XCTAssertEqual(entry.inGilShop, true)
        XCTAssertTrue(entry.isShopPurchase)
    }

    func testPriceWithoutShopFlagIsNotAShopPurchase() throws {
        let entry = try entry(from: #"{"price_mid": 9}"#)

        XCTAssertEqual(entry.priceMid, 9)
        XCTAssertNil(entry.inGilShop)
        XCTAssertFalse(entry.isShopPurchase)
    }

    func testExplicitlyFalseShopFlagIsNotAShopPurchase() throws {
        let entry = try entry(from: #"{"price_mid": 9, "in_gil_shop": false}"#)

        XCTAssertFalse(entry.isShopPurchase)
    }

    /// Item 38613 in the shipped data is sold by a shop but carries no price.
    func testShopFlagWithoutPriceIsStillAShopPurchase() throws {
        let entry = try entry(from: #"{"in_gil_shop": true}"#)

        XCTAssertNil(entry.priceMid)
        XCTAssertTrue(entry.isShopPurchase)
    }

    func testEmptyEntryDecodesWithNothingSet() throws {
        let entry = try entry(from: "{}")

        XCTAssertNil(entry.priceMid)
        XCTAssertNil(entry.inGilShop)
        XCTAssertFalse(entry.isShopPurchase)
    }

    /// The file is keyed by item id as a string and carries a `_meta` block the app ignores.
    func testResponseDecodesShopMapAndIgnoresMetadata() throws {
        let json = """
        {
          "_meta": { "source": "Item.csv", "item_count": 2 },
          "shop": {
            "1601": { "price_mid": 63, "in_gil_shop": true },
            "2": { "price_mid": 9 }
          }
        }
        """

        let response = try JSONDecoder().decode(ItemShopDataResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.shop.count, 2)
        XCTAssertTrue(try XCTUnwrap(response.shop["1601"]).isShopPurchase)
        XCTAssertFalse(try XCTUnwrap(response.shop["2"]).isShopPurchase)
        XCTAssertNil(response.shop["99999"])
    }
}
