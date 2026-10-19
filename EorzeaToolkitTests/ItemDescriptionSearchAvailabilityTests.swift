import XCTest
@testable import EorzeaToolkit

/// The 「模型狀態」 table of prompts/item-description-search.md (AC-7). How the item search
/// uses these flags is in `ItemDescriptionSearchTests`.
final class ItemDescriptionSearchAvailabilityTests: XCTestCase {
    /// An exhaustive switch, so a new state does not compile until it has a row here.
    func testEachStateShowsTheButtonAndSearchesAsTheTableSays() {
        for availability in ItemDescriptionSearchAvailability.allCases {
            let expected: (showsButton: Bool, canSearch: Bool)
            switch availability {
            case .available:
                expected = (true, true)
            case .appleIntelligenceNotEnabled, .modelNotReady:
                expected = (true, false)
            case .unavailable:
                expected = (false, false)
            }

            XCTAssertEqual(availability.showsButton, expected.showsButton, "\(availability)")
            XCTAssertEqual(availability.canSearch, expected.canSearch, "\(availability)")
        }
    }

    func testBeforeIOS26ThereIsNoDescriptionSearch() {
        let engine = ItemDescriptionSearchEngine.unsupported

        XCTAssertFalse(engine.isSupported)
        XCTAssertEqual(engine.availability(), .unavailable)
    }
}
