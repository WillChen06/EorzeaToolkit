import XCTest
@testable import EorzeaToolkit

/// The market server is a lasting choice: the app should open on the server the player picked
/// last time. Each test uses its own UserDefaults suite, never the app's.
@MainActor
final class MarketPriceSettingsTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        suiteName = "MarketPriceSettingsTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testDefaultsToChocoboWithoutASavedServer() {
        XCTAssertEqual(MarketPriceSettings(defaults: defaults).selectedScope, .chocobo)
    }

    func testRestoresTheServerPickedLastTime() {
        MarketPriceSettings(defaults: defaults).selectedScope = .ifrit

        XCTAssertEqual(MarketPriceSettings(defaults: defaults).selectedScope, .ifrit)
    }

    func testUnknownSavedServerFallsBackToChocobo() {
        defaults.set("removedServer", forKey: "marketPrice.selectedScope")

        XCTAssertEqual(MarketPriceSettings(defaults: defaults).selectedScope, .chocobo)
    }
}
