import XCTest
@testable import EorzeaToolkit

@MainActor
final class TreasureMapGradeSortingTests: XCTestCase {
    /// G1 to G18 in an order that is neither sorted nor reversed, so the result has to come from sorting.
    private let scrambledMaps = [7, 18, 1, 12, 3, 10, 15, 9, 2, 16, 5, 11, 14, 8, 4, 17, 6, 13]
        .map { TreasureMapFixture.map(grade: "G\($0)") }

    func testDefaultOrderIsDescendingByGradeNumber() {
        let direction = TreasureMapFeature.State().sortDirection

        let grades = TreasureMapQuery.sorted(scrambledMaps, direction: direction).map(\.grade)

        XCTAssertEqual(grades.first, "G18")
        XCTAssertEqual(grades.last, "G1")
        XCTAssertEqual(grades, (1...18).reversed().map { "G\($0)" })
    }

    func testAscendingOrderRanksGradeNumberFromG1ToG18() {
        var direction = TreasureMapFeature.State().sortDirection
        direction.toggle()

        let grades = TreasureMapQuery.sorted(scrambledMaps, direction: direction).map(\.grade)

        XCTAssertEqual(grades.first, "G1")
        XCTAssertEqual(grades.last, "G18")
        XCTAssertEqual(grades, (1...18).map { "G\($0)" })
    }

    func testGradeNumberComparisonRanksG10AboveG9InDescendingOrder() {
        let maps = [
            TreasureMapFixture.map(grade: "G9"),
            TreasureMapFixture.map(grade: "G10")
        ]

        XCTAssertEqual(TreasureMapQuery.sorted(maps, direction: .descending).map(\.grade), ["G10", "G9"])
    }

    func testMalformedGradesSortAfterValidGradesWithoutCrashing() {
        let maps = [
            TreasureMapFixture.map(grade: "unknown"),
            TreasureMapFixture.map(grade: "G2"),
            TreasureMapFixture.map(grade: "G1")
        ]

        XCTAssertEqual(
            TreasureMapQuery.sorted(maps, direction: .ascending).map(\.grade),
            ["G1", "G2", "unknown"]
        )
    }
}

@MainActor
final class TreasureMapFilterOptionsTests: XCTestCase {
    func testVersionOptionsAreDerivedFromLoadedExpansionsDeduplicatedAndSorted() {
        let expansions = ["7.3", "2.1", "6.3", "4.0", "3.0", "6.0", "5.0", "7.0"]
        let maps = expansions.map { TreasureMapFixture.map(expansion: $0) }

        XCTAssertEqual(TreasureMapQuery.versionOptions(from: maps), [2, 3, 4, 5, 6, 7])
    }

    func testLevelOptionsAreDerivedFromLoadedDataAndIncludeLevelsNotInCurrentFixture() {
        let levels = [100, 40, 50, 45, 60, 55, 70, 80, 90, 110, 50]
        let maps = levels.map { TreasureMapFixture.map(level: $0) }

        XCTAssertEqual(TreasureMapQuery.levelOptions(from: maps), [40, 45, 50, 55, 60, 70, 80, 90, 100, 110])
    }

    func testExpansionsSharingMajorVersionGroupIntoOneOption() {
        let maps = [
            TreasureMapFixture.map(expansion: "6.0"),
            TreasureMapFixture.map(expansion: "6.3")
        ]

        XCTAssertEqual(TreasureMapQuery.versionOptions(from: maps), [6])
    }

    func testMalformedExpansionsAreIgnoredWithoutCrashing() {
        let maps = [
            TreasureMapFixture.map(expansion: "unknown"),
            TreasureMapFixture.map(expansion: "6.3")
        ]

        XCTAssertEqual(TreasureMapQuery.versionOptions(from: maps), [6])
        XCTAssertEqual(
            TreasureMapQuery.filtered(maps, by: TreasureMapFilter(selectedMajorVersions: [6])).map(\.expansion),
            ["6.3"]
        )
    }
}

@MainActor
final class TreasureMapFilteringTests: XCTestCase {
    func testSelectingMultipleVersionsMatchesAnyOfThem() {
        let maps = TreasureMapFixture.filteringMaps
        let filter = TreasureMapFilter(selectedMajorVersions: [6, 7])

        let result = TreasureMapQuery.filtered(maps, by: filter)

        XCTAssertEqual(Set(result.compactMap(\.expansionMajorVersion)), [6, 7])
        XCTAssertEqual(result.count, 4)
    }

    func testSelectingMultipleLevelsMatchesAnyOfThem() {
        let maps = TreasureMapFixture.filteringMaps
        let filter = TreasureMapFilter(selectedLevels: [90, 100])

        let result = TreasureMapQuery.filtered(maps, by: filter)

        XCTAssertEqual(Set(result.map(\.level)), [90, 100])
        XCTAssertEqual(result.count, 3)
    }

    func testVersionAndLevelFiltersCombineWithLogicalAnd() {
        let filter = TreasureMapFilter(
            selectedMajorVersions: [6, 7],
            selectedLevels: [90, 100]
        )

        let result = TreasureMapQuery.filtered(TreasureMapFixture.filteringMaps, by: filter)

        XCTAssertEqual(Set(result.map(\.id)), ["G3", "G4"])
    }

    func testEmptyVersionSelectionDoesNotRestrictResults() {
        let filter = TreasureMapFilter(selectedLevels: [90])

        let result = TreasureMapQuery.filtered(TreasureMapFixture.filteringMaps, by: filter)

        XCTAssertEqual(Set(result.map(\.id)), ["G3", "G6"])
    }

    func testEmptyLevelSelectionDoesNotRestrictResults() {
        let filter = TreasureMapFilter(selectedMajorVersions: [6])

        let result = TreasureMapQuery.filtered(TreasureMapFixture.filteringMaps, by: filter)

        XCTAssertEqual(Set(result.map(\.id)), ["G2", "G3"])
    }
}
