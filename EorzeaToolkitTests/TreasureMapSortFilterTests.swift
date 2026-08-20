import XCTest
@testable import EorzeaToolkit

@MainActor
final class TreasureMapGradeSortingTests: XCTestCase {
    func testDefaultOrderIsDescendingByGradeNumber() {
        let viewModel = TreasureMapViewModel(maps: (1...18).map { TreasureMapFixture.map(grade: "G\($0)") })

        XCTAssertEqual(viewModel.displayedMaps.first?.grade, "G18")
        XCTAssertEqual(viewModel.displayedMaps.last?.grade, "G1")
    }

    func testGradeNumberComparisonRanksG10AboveG9InDescendingOrder() {
        let maps = [
            TreasureMapFixture.map(grade: "G9"),
            TreasureMapFixture.map(grade: "G10")
        ]

        XCTAssertEqual(TreasureMapQuery.sorted(maps, direction: .descending).map(\.grade), ["G10", "G9"])
    }

    func testAscendingOrderRanksGradeNumberFromG1ToG18() {
        let viewModel = TreasureMapViewModel(maps: (1...18).map { TreasureMapFixture.map(grade: "G\($0)") })

        viewModel.toggleSortDirection()

        XCTAssertEqual(viewModel.displayedMaps.first?.grade, "G1")
        XCTAssertEqual(viewModel.displayedMaps.last?.grade, "G18")
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
        let viewModel = TreasureMapViewModel(maps: expansions.map { TreasureMapFixture.map(expansion: $0) })

        XCTAssertEqual(viewModel.versionOptions, [2, 3, 4, 5, 6, 7])
    }

    func testExpansionsSharingMajorVersionGroupIntoOneOption() {
        let maps = [
            TreasureMapFixture.map(expansion: "6.0"),
            TreasureMapFixture.map(expansion: "6.3")
        ]

        XCTAssertEqual(TreasureMapQuery.versionOptions(from: maps), [6])
    }

    func testLevelOptionsAreDerivedFromLoadedDataAndIncludeLevelsNotInCurrentFixture() {
        let levels = [100, 40, 50, 45, 60, 55, 70, 80, 90, 110, 50]
        let viewModel = TreasureMapViewModel(maps: levels.map { TreasureMapFixture.map(level: $0) })

        XCTAssertEqual(viewModel.levelOptions, [40, 45, 50, 55, 60, 70, 80, 90, 100, 110])
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

@MainActor
final class TreasureMapViewModelFilterTests: XCTestCase {
    func testFilterBadgeCountEqualsSelectedVersionsPlusSelectedLevels() {
        let viewModel = TreasureMapViewModel(maps: TreasureMapFixture.filteringMaps)

        viewModel.toggleMajorVersion(6)
        viewModel.toggleMajorVersion(7)
        viewModel.toggleLevel(90)
        viewModel.toggleLevel(100)

        XCTAssertEqual(viewModel.activeFilterCount, 4)
    }

    func testTogglingFilterSelectionUpdatesDisplayedListWithoutSeparateApplyAction() {
        let viewModel = TreasureMapViewModel(maps: TreasureMapFixture.filteringMaps)

        viewModel.toggleMajorVersion(7)

        XCTAssertEqual(Set(viewModel.displayedMaps.map(\.id)), ["G4", "G5"])
    }

    func testClearAllFiltersEmptiesSelectionsAndRestoresFullList() {
        let maps = TreasureMapFixture.filteringMaps
        let viewModel = TreasureMapViewModel(maps: maps)
        viewModel.toggleMajorVersion(7)
        viewModel.toggleLevel(100)

        viewModel.clearFilters()

        XCTAssertTrue(viewModel.filter.selectedMajorVersions.isEmpty)
        XCTAssertTrue(viewModel.filter.selectedLevels.isEmpty)
        XCTAssertEqual(viewModel.displayedMaps.count, maps.count)
    }

    func testClearingFiltersFromEmptyResultStateRestoresFullyLoadedMapSet() {
        let maps = TreasureMapFixture.filteringMaps
        let viewModel = TreasureMapViewModel(maps: maps)
        viewModel.toggleMajorVersion(2)
        viewModel.toggleLevel(100)
        XCTAssertTrue(viewModel.displayedMaps.isEmpty)

        viewModel.clearFilters()

        XCTAssertEqual(viewModel.displayedMaps.count, maps.count)
    }

    func testClearingFiltersPreservesCurrentSortDirection() {
        let viewModel = TreasureMapViewModel(maps: TreasureMapFixture.filteringMaps)
        viewModel.toggleSortDirection()
        viewModel.toggleMajorVersion(7)

        viewModel.clearFilters()

        XCTAssertEqual(viewModel.sortDirection, .ascending)
        XCTAssertEqual(viewModel.displayedMaps.map(\.grade), ["G1", "G2", "G3", "G4", "G5", "G6"])
    }

    func testResetPresentationStateRestoresDescendingOrderAndClearsFilters() {
        let viewModel = TreasureMapViewModel(maps: TreasureMapFixture.filteringMaps)
        viewModel.toggleSortDirection()
        viewModel.toggleMajorVersion(7)
        viewModel.toggleLevel(100)

        viewModel.resetPresentationState()

        XCTAssertEqual(viewModel.sortDirection, .descending)
        XCTAssertFalse(viewModel.isFilterActive)
        XCTAssertEqual(viewModel.displayedMaps.map(\.grade), ["G6", "G5", "G4", "G3", "G2", "G1"])
    }
}

private enum TreasureMapFixture {
    static let filteringMaps = [
        map(grade: "G1", level: 40, expansion: "2.1"),
        map(grade: "G2", level: 80, expansion: "6.0"),
        map(grade: "G3", level: 90, expansion: "6.3"),
        map(grade: "G4", level: 100, expansion: "7.0"),
        map(grade: "G5", level: 70, expansion: "7.3"),
        map(grade: "G6", level: 90, expansion: "5.0")
    ]

    static func map(
        grade: String = "G1",
        level: Int = 40,
        expansion: String = "2.1"
    ) -> TreasureMap {
        TreasureMap(
            id: grade,
            itemId: grade.hashValue,
            grade: grade,
            name: grade,
            nameEn: grade,
            nameJa: grade,
            level: level,
            expansion: expansion,
            type: .solo,
            gatheringTypes: [],
            gatheringZoneIds: [],
            gatheringNodes: []
        )
    }
}
