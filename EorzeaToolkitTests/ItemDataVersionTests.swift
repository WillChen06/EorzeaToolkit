import XCTest
@testable import EorzeaToolkit

/// `ItemDataVersion` decides whether cached or downloaded item data may replace the bundled
/// data, so a parsing or ordering mistake would either hide new data or let old data win.
final class ItemDataVersionTests: XCTestCase {
    func testParsesTheBuildDataFormat() throws {
        let version = try XCTUnwrap(ItemDataVersion("2026.09.14.0000.0000-r1"))

        XCTAssertEqual(version.gameVersion, [2026, 9, 14, 0, 0])
        XCTAssertEqual(version.revision, 1)
    }

    /// The remote file published before the Traditional Chinese data uses this format.
    func testOldRemoteFormatDoesNotParse() {
        XCTAssertNil(ItemDataVersion("2026-05-17-v2"))
    }

    func testMalformedVersionsDoNotParse() {
        let malformed = [
            "",
            "2026.09.14.0000.0000",
            "2026.09.14-r1",
            "2026.09.14.0000.0000.0000-r1",
            "2026.09.14.0000.0000-r",
            "2026.09.14.0000.0000-rX",
            "2026.09.14.0000.0000-r-1",
            "2026.09.14.0000.0000-r1-r2",
            "2026..14.0000.0000-r1",
        ]

        for string in malformed {
            XCTAssertNil(ItemDataVersion(string), string)
        }
    }

    func testRevisionsCompareNumerically() throws {
        let nine = try XCTUnwrap(ItemDataVersion("2026.09.14.0000.0000-r9"))
        let ten = try XCTUnwrap(ItemDataVersion("2026.09.14.0000.0000-r10"))

        XCTAssertLessThan(nine, ten)
    }

    func testGameVersionOutranksRevision() throws {
        let olderGameVersion = try XCTUnwrap(ItemDataVersion("2026.07.22.0000.0000-r9"))
        let newerGameVersion = try XCTUnwrap(ItemDataVersion("2026.09.14.0000.0000-r1"))

        XCTAssertLessThan(olderGameVersion, newerGameVersion)
    }

    func testIsNewerRequiresAStrictlyNewerParseableCandidate() {
        let current = "2026.09.14.0000.0000-r1"

        XCTAssertTrue(ItemDataVersion.isNewer("2026.09.14.0000.0000-r2", than: current))
        XCTAssertFalse(ItemDataVersion.isNewer(current, than: current))
        XCTAssertFalse(ItemDataVersion.isNewer("2026.07.22.0000.0000-r5", than: current))
        XCTAssertFalse(ItemDataVersion.isNewer("2026-05-17-v2", than: current))
        XCTAssertFalse(ItemDataVersion.isNewer(nil, than: current))
    }

    func testAnyParseableCandidateIsNewerThanAnUnparseableCurrentVersion() {
        XCTAssertTrue(ItemDataVersion.isNewer("2026.09.14.0000.0000-r1", than: "2026-05-17-v2"))
        XCTAssertTrue(ItemDataVersion.isNewer("2026.09.14.0000.0000-r1", than: nil))
    }
}
