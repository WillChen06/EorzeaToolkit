import XCTest
@testable import EorzeaToolkit

/// How the on-device model's status becomes description search availability (AC-7). It needs
/// iOS 26; `ItemDescriptionSearchAvailabilityTests` covers what each availability means.
final class ItemQueryModelStatusAvailabilityTests: XCTestCase {
    /// Each reason the on-device model gives, as the table lists it.
    func testEachModelStatusMapsToItsRow() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("ItemQueryModelStatus needs iOS 26")
        }
        for status in [
            ItemQueryModelStatus.available,
            .appleIntelligenceNotEnabled,
            .modelNotReady,
            .deviceNotEligible,
            .traditionalChineseNotSupported,
            .unavailable
        ] {
            let expected: ItemDescriptionSearchAvailability
            switch status {
            case .available:
                expected = .available
            case .appleIntelligenceNotEnabled:
                expected = .appleIntelligenceNotEnabled
            case .modelNotReady:
                expected = .modelNotReady
            case .deviceNotEligible, .traditionalChineseNotSupported, .unavailable:
                expected = .unavailable
            }

            XCTAssertEqual(status.descriptionSearchAvailability, expected, "\(status)")
        }
    }
}
