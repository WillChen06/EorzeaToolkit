import XCTest
@testable import EorzeaToolkit

/// The item search's equip level filter: a narrowed range keeps only equipment whose equip level
/// is in it, and the full range filters nothing.
final class ItemEquipLevelFilterTests: XCTestCase {
    // MARK: - Search results

    func testANarrowedRangeKeepsEquipmentWithinItInclusive() {
        let items = [79, 80, 85, 90, 91].map { equipment(level: $0) }

        XCTAssertEqual(levels(search(items, equipLevelRange: 80...90)), [80, 85, 90])
    }

    func testARangeOfOneLevelKeepsOnlyThatLevel() {
        let items = [79, 80, 81].map { equipment(level: $0) }

        XCTAssertEqual(levels(search(items, equipLevelRange: 80...80)), [80])
    }

    func testARangeEndingAtEitherBoundStillFilters() {
        let items = [1, 50, 100].map { equipment(level: $0) }

        XCTAssertEqual(levels(search(items, equipLevelRange: 1...99)), [1, 50])
        XCTAssertEqual(levels(search(items, equipLevelRange: 2...100)), [50, 100])
    }

    /// Items that cannot be equipped have an equip level too, often one inside the range.
    func testANarrowedRangeDropsItemsThatCannotBeEquipped() {
        let items = [
            notEquipment(id: 1, level: 1),
            notEquipment(id: 2, level: 80),
            notEquipment(id: 3, level: 50)
        ]

        XCTAssertTrue(search(items, equipLevelRange: 1...99).isEmpty)
        XCTAssertTrue(search(items, equipLevelRange: 2...100).isEmpty)
        XCTAssertTrue(search(items, equipLevelRange: 80...80).isEmpty)
        XCTAssertTrue(search(items, equipLevelRange: 1...1).isEmpty)
    }

    func testTheFullRangeKeepsEveryItem() {
        let items = [
            equipment(id: 1, level: 1),
            equipment(id: 2, level: 100),
            notEquipment(id: 3, level: 1),
            notEquipment(id: 4, level: 80),
            equipment(id: 5, level: 0)
        ]

        XCTAssertEqual(ItemFilter().equipLevelRange, 1...100)
        XCTAssertEqual(Set(search(items, filter: ItemFilter()).map(\.id)), Set(items.map(\.id)))
    }

    // MARK: - Filter state

    func testANarrowedRangeCountsAsOneActiveFilter() {
        var filter = ItemFilter()
        XCTAssertFalse(filter.isActive)
        XCTAssertEqual(filter.activeFilterCount, 0)

        for range in [80...100, 1...99, 2...100, 80...80] {
            filter.equipLevelRange = range
            XCTAssertTrue(filter.isActive, "\(range)")
            XCTAssertEqual(filter.activeFilterCount, 1, "\(range)")
        }

        filter.ilvlRange = 600...ItemFilter.defaultIlvlRange.upperBound
        XCTAssertEqual(filter.activeFilterCount, 2)

        filter.ilvlRange = ItemFilter.defaultIlvlRange
        filter.equipLevelRange = 1...100
        XCTAssertFalse(filter.isActive)
        XCTAssertEqual(filter.activeFilterCount, 0)
    }

    /// Compared with the localized text rather than a literal, so the test passes in any language.
    func testTheSummaryShowsANarrowedRange() throws {
        var filter = ItemFilter()
        filter.equipLevelRange = 80...100

        let parts = summary(of: filter)
        XCTAssertEqual(parts, [L10n.ItemSearch.Filter.summaryEquipLevel(lowerBound: 80, upperBound: 100)])
        let part = try XCTUnwrap(parts.first)
        XCTAssertTrue(part.contains("80") && part.contains("100"), part)
        XCTAssertNotEqual(part, L10n.ItemSearch.Filter.summaryItemLevel(lowerBound: 80, upperBound: 100))

        filter.equipLevelRange = 1...100
        XCTAssertEqual(summary(of: filter), [])
    }

    func testTheEquipLevelFollowsTheItemLevelInTheSummary() {
        var filter = ItemFilter()
        filter.equipLevelRange = 90...100
        filter.ilvlRange = 600...700

        XCTAssertEqual(summary(of: filter), [
            L10n.ItemSearch.Filter.summaryItemLevel(lowerBound: 600, upperBound: 700),
            L10n.ItemSearch.Filter.summaryEquipLevel(lowerBound: 90, upperBound: 100)
        ])
    }

    // MARK: - Helpers

    private func search(_ items: [Item], equipLevelRange: ClosedRange<Int>) -> [Item] {
        var filter = ItemFilter()
        filter.equipLevelRange = equipLevelRange
        return search(items, filter: filter)
    }

    /// Every fixture item's name contains the query, so only the filter decides.
    private func search(_ items: [Item], filter: ItemFilter) -> [Item] {
        ItemSearchViewModel.searchItems(items, query: "道具", filter: filter, classjobJobSetsById: [:]).items
    }

    private func levels(_ items: [Item]) -> [Int] {
        items.map(\.equipLevel).sorted()
    }

    /// The summary the filter bar shows, with no category, job or slot selected.
    private func summary(of filter: ItemFilter) -> [String] {
        filter.summaryParts(uiCategoryNamesById: [:], jobNamesByAbbr: [:], equipSlotNamesById: [:])
    }
}

/// The filter sheet's sliders go through these methods.
@MainActor
final class ItemSearchViewModelEquipLevelTests: XCTestCase {
    func testResetRestoresTheFullRange() {
        let viewModel = ItemSearchViewModel()
        viewModel.updateMaximumEquipLevel(90)
        viewModel.updateMinimumEquipLevel(80)
        XCTAssertEqual(viewModel.filter.equipLevelRange, 80...90)

        viewModel.resetFilter()

        XCTAssertEqual(viewModel.filter.equipLevelRange, 1...100)
        XCTAssertFalse(viewModel.filter.isActive)
    }

    func testTheMinimumCannotPassTheMaximum() {
        let viewModel = ItemSearchViewModel()
        viewModel.updateMaximumEquipLevel(80)
        viewModel.updateMinimumEquipLevel(90)

        XCTAssertEqual(viewModel.filter.equipLevelRange, 80...80)
    }

    func testTheMaximumCannotFallBelowTheMinimum() {
        let viewModel = ItemSearchViewModel()
        viewModel.updateMinimumEquipLevel(80)
        viewModel.updateMaximumEquipLevel(70)

        XCTAssertEqual(viewModel.filter.equipLevelRange, 80...80)
    }

    func testLevelsOutsideTheFullRangeAreClamped() {
        let viewModel = ItemSearchViewModel()
        viewModel.updateMinimumEquipLevel(0)
        viewModel.updateMaximumEquipLevel(120)

        XCTAssertEqual(viewModel.filter.equipLevelRange, 1...100)
        XCTAssertFalse(viewModel.filter.isActive)
    }
}

/// Equip slot 1 is the main hand; any slot other than 0 counts as equipment.
private func equipment(id: Int? = nil, level: Int) -> Item {
    item(id: id ?? level, equipSlot: 1, equipLevel: level)
}

private func notEquipment(id: Int, level: Int) -> Item {
    item(id: id, equipSlot: 0, equipLevel: level)
}

private func item(id: Int, equipSlot: Int, equipLevel: Int) -> Item {
    Item(
        id: id,
        nameTw: "測試道具\(id)",
        iconId: 0,
        iconPath: "",
        ilvl: 1,
        rarity: 1,
        canBeHq: false,
        isUntradable: false,
        equipSlot: equipSlot,
        equipLevel: equipLevel
    )
}
