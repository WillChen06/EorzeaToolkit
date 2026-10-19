import XCTest
@testable import EorzeaToolkit

/// With an empty search field, an active filter alone lists its items
/// (prompts/item-description-search.md, 「只用 filter 搜尋」, AC-24).
@MainActor
final class ItemSearchFilterOnlyTests: XCTestCase {
    private static let whiteMage = 1
    private static let blackMage = 2

    private static let data = ItemDataResponse(
        items: [
            item(id: 1, name: "白魔長袍B", ilvl: 600, job: whiteMage),
            item(id: 2, name: "白魔長袍A", ilvl: 600, job: whiteMage),
            item(id: 3, name: "白魔頭冠", ilvl: 700, job: whiteMage),
            item(id: 4, name: "黑魔長袍", ilvl: 650, job: blackMage),
            item(id: 5, name: "藥水", ilvl: 1, job: 0)
        ],
        classjobCategories: [
            ClassJobCategory(id: whiteMage, nameTw: "白魔道士", jobs: ["WHM"]),
            ClassJobCategory(id: blackMage, nameTw: "黑魔道士", jobs: ["BLM"])
        ]
    )

    private func loadedViewModel() async -> ItemSearchViewModel {
        let viewModel = ItemSearchViewModel(loadData: { Self.data }, refreshData: { _ in nil })
        viewModel.loadItems()
        await viewModel.waitUntilLoaded()
        return viewModel
    }

    /// Every match, not just the first page, in the order a name search uses: item level
    /// descending, then name. The names differ in a Latin letter, which sorts the same in every
    /// locale.
    func testAnActiveFilterListsItsItemsWithoutASearchText() async {
        let viewModel = await loadedViewModel()

        viewModel.toggleJob("WHM")
        await viewModel.waitUntilSearchFinishes()

        XCTAssertTrue(viewModel.isFilterOnlySearch)
        XCTAssertFalse(viewModel.isWaitingForSearch)
        XCTAssertEqual(viewModel.totalMatchCount, 3)
        XCTAssertEqual(viewModel.results.map(\.id), [3, 2, 1])
    }

    func testASearchTextOfOnlySpacesIsEmpty() async {
        let viewModel = await loadedViewModel()

        viewModel.updateSearchQuery("   ")
        viewModel.toggleJob("BLM")
        await viewModel.waitUntilSearchFinishes()

        XCTAssertEqual(viewModel.results.map(\.id), [4])
    }

    func testTheDefaultFilterListsNothingWithoutASearchText() async {
        let viewModel = await loadedViewModel()
        await viewModel.waitUntilSearchFinishes()

        XCTAssertTrue(viewModel.isWaitingForSearch)
        XCTAssertFalse(viewModel.isFilterOnlySearch)
        XCTAssertEqual(viewModel.totalMatchCount, 0)
        XCTAssertTrue(viewModel.results.isEmpty)
    }

    func testResettingTheFilterClearsTheList() async {
        let viewModel = await loadedViewModel()
        viewModel.toggleJob("WHM")
        await viewModel.waitUntilSearchFinishes()

        viewModel.resetFilter()
        await viewModel.waitUntilSearchFinishes()

        XCTAssertTrue(viewModel.isWaitingForSearch)
        XCTAssertTrue(viewModel.results.isEmpty)
    }

    /// A filter that keeps nothing is a filter-only search with no results.
    func testAFilterThatKeepsNothingIsStillAFilterOnlySearch() async {
        let viewModel = await loadedViewModel()

        viewModel.updateMinimumItemLevel(795)
        await viewModel.waitUntilSearchFinishes()

        XCTAssertTrue(viewModel.isFilterOnlySearch)
        XCTAssertTrue(viewModel.results.isEmpty)
    }

    func testANameStillNarrowsTheFilter() async {
        let viewModel = await loadedViewModel()

        viewModel.toggleJob("WHM")
        viewModel.updateSearchQuery("長袍")
        await viewModel.waitUntilSearchFinishes()

        XCTAssertFalse(viewModel.isFilterOnlySearch)
        XCTAssertEqual(viewModel.results.map(\.id), [2, 1])
    }

    func testSearchingWithAnEmptyQueryKeepsWhatTheFilterKeeps() {
        var filter = ItemFilter()
        filter.selectedJobAbbrs = ["WHM", "BLM"]

        let result = ItemSearchViewModel.searchItems(
            Self.data.items,
            query: "",
            filter: filter,
            classjobJobSetsById: [Self.whiteMage: ["WHM"], Self.blackMage: ["BLM"]]
        )

        XCTAssertEqual(result.items.map(\.id), [3, 4, 2, 1])
        XCTAssertEqual(result.totalCount, 4)
    }

    private static func item(id: Int, name: String, ilvl: Int, job: Int) -> Item {
        Item(
            id: id,
            nameTw: name,
            iconId: 0,
            iconPath: "",
            ilvl: ilvl,
            rarity: 1,
            canBeHq: false,
            isUntradable: false,
            classjobCategoryId: job
        )
    }
}
