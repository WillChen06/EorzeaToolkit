//
//  ItemSearchFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/12.
//

import Testing
import ComposableArchitecture
@testable import EorzeaToolkit

@MainActor
struct ItemSearchFeatureTests {

    @Test func taskLoadsCatalogWithoutRemoteRefresh() async {
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = {
                catalog
            }
            
            $0.itemData.refresh = { version in
                #expect(version == catalog.version)
                return nil
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
        }
        
        await store.receive(\.refreshResponse, nil)
    }
    
    @Test func taskLoadsCatalogWithRemoteRefresh() async {
        let refreshVersion = "v2"
        let catalog = ItemSearchFixture.catalog()
        let refreshCatalog = ItemSearchFixture.catalog(version: refreshVersion)
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = {
                catalog
            }
            
            $0.itemData.refresh = { _ in
                refreshCatalog
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
        }
        
        await store.receive(\.refreshResponse) {
            $0.catalog = refreshCatalog
        }
    }
    
    @Test func remoteRefreshFailureKeepsTheCatalog() async {
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = {
                catalog
            }
            
            $0.itemData.refresh = { _ in
                throw FetchError()
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
        }
        
        await store.receive(\.refreshResponse, nil)
    }

    @Test func taskFailureShowsError() async {
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = {
                throw FetchError()
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.failure) {
            $0.loadState = .failed("fetch failed")
        }
    }
    
    @Test(arguments: [ItemSearchFeature.LoadState.loading, .loaded])
    func taskDoesNothingWhenLoadingOrLoaded(loadState: ItemSearchFeature.LoadState) async {
        let store = TestStore(initialState: ItemSearchFeature.State(loadState: loadState)) {
            ItemSearchFeature()
        }
        
        await store.send(.task)
    }
    
    @Test func taskRetriesAfterFailure() async {
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(initialState: ItemSearchFeature.State(loadState: .failed("x"))) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = { catalog }
            $0.itemData.refresh = { _ in nil }
        }

        await store.send(.task) { $0.loadState = .loading }
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
        }
        await store.receive(\.refreshResponse, nil)
    }
    
    @Test func searchWithDebounce() async {
        let clock = TestClock()
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(
            initialState: ItemSearchFeature.State(loadState: .loaded, catalog: catalog)
        ) {
            ItemSearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        
        await store.send(.searchQueryChanged("白")) {
            $0.query = "白"
            $0.isSearching = true
        }
        
        await clock.advance(by: .milliseconds(100))
        
        await store.send(.searchQueryChanged("白魔")) {
            $0.query = "白魔"
        }
        
        let expected = [3, 2, 1].compactMap { catalog.itemsByID[$0] }
        
        await clock.advance(by: .milliseconds(300))
        await store.receive(\.searchResponse) {
            $0.allResults = expected
            $0.visibleResultCount = expected.count
            $0.isSearching = false
        }
    }

    /// Clearing the text before the debounce ends cancels the search: no response arrives,
    /// even once the time has passed, and nothing is searching.
    @Test func clearingTheQueryCancelsTheSearch() async {
        let clock = TestClock()
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(
            initialState: ItemSearchFeature.State(loadState: .loaded, catalog: catalog)
        ) {
            ItemSearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        
        await store.send(.searchQueryChanged("白")) {
            $0.query = "白"
            $0.isSearching = true
        }
        await clock.advance(by: .milliseconds(300))
        let whiteItems = [3, 2, 1].compactMap { catalog.itemsByID[$0] }
        await store.receive(\.searchResponse) {
            $0.allResults = whiteItems
            $0.visibleResultCount = whiteItems.count
            $0.isSearching = false
        }

        await store.send(.searchQueryChanged("白魔")) {
            $0.query = "白魔"
            $0.isSearching = true
        }
        await clock.advance(by: .milliseconds(100))

        await store.send(.searchQueryChanged("")) {
            $0.query = ""
            $0.allResults = []
            $0.visibleResultCount = 0
            $0.isSearching = false
        }
        await clock.advance(by: .milliseconds(300))
    }

    /// A search text of only spaces counts as empty, so nothing is searched.
    @Test(arguments: [" ", "   ", "　", "\n"])
    func aQueryOfOnlySpacesIsEmpty(query: String) async {
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(
            initialState: ItemSearchFeature.State(loadState: .loaded, catalog: catalog)
        ) {
            ItemSearchFeature()
        }
        
        await store.send(.searchQueryChanged(query)) {
            $0.query = query
        }
    }
    
    @Test func aQueryOfOnlySpacesKeepsWhatTheFilterKeeps() async {
        let clock = TestClock()
        let catalog = ItemSearchFixture.catalog()
        var filter = ItemFilter()
        filter.selectedJobAbbrs = ["BLM"]
        let store = TestStore(
            initialState: ItemSearchFeature.State(loadState: .loaded, catalog: catalog, filter: filter)
        ) {
            ItemSearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.searchQueryChanged("   ")) {
            $0.query = "   "
            $0.isSearching = true
        }
        await clock.advance(by: .milliseconds(300))
        let blackMageItems = [4].compactMap { catalog.itemsByID[$0] }
        await store.receive(\.searchResponse) {
            $0.allResults = blackMageItems
            $0.visibleResultCount = blackMageItems.count
            $0.isSearching = false
        }
    }

    /// Text typed before the items load is not searched yet; it is searched, without a
    /// debounce, as soon as they load.
    @Test func aQueryTypedBeforeLoadingIsSearchedOnceLoaded() async {
        let clock = TestClock()
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.itemData.load = { catalog }
            // Held until the clock moves, so the search answers first.
            $0.itemData.refresh = { _ in
                try await clock.sleep(for: .seconds(1))
                return nil
            }
        }

        await store.send(.searchQueryChanged("長袍")) {
            $0.query = "長袍"
        }

        await store.send(.task) {
            $0.loadState = .loading
        }
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
            $0.isSearching = true
        }

        // Received before the clock moves: the search waits for no debounce.
        let robes = [4, 2, 1].compactMap { catalog.itemsByID[$0] }
        await store.receive(\.searchResponse) {
            $0.allResults = robes
            $0.visibleResultCount = robes.count
            $0.isSearching = false
        }

        await clock.advance(by: .seconds(1))
        await store.receive(\.refreshResponse, nil)
    }

    /// A remote update searches the current text again, without a debounce, in the new
    /// catalog.
    @Test func aRemoteUpdateSearchesAgain() async {
        let clock = TestClock()
        let catalog = ItemSearchFixture.catalog(version: "v1")
        let updated = ItemSearchFixture.catalog(
            items: ItemSearchFixture.items + [ItemSearchFixture.item(id: 6, name: "新長袍", ilvl: 660)],
            version: "v2"
        )
        let store = TestStore(initialState: ItemSearchFeature.State(query: "長袍")) {
            ItemSearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.itemData.load = { catalog }
            // Held until the clock moves, so the first search answers first.
            $0.itemData.refresh = { version in
                #expect(version == "v1")
                try await clock.sleep(for: .seconds(1))
                return updated
            }
        }

        await store.send(.task) {
            $0.loadState = .loading
        }
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
            $0.isSearching = true
        }
        let robes = [4, 2, 1].compactMap { catalog.itemsByID[$0] }
        await store.receive(\.searchResponse) {
            $0.allResults = robes
            $0.visibleResultCount = robes.count
            $0.isSearching = false
        }

        await clock.advance(by: .seconds(1))
        await store.receive(\.refreshResponse) {
            $0.catalog = updated
            $0.isSearching = true
        }

        // Received without moving the clock again: the second search waits for no debounce.
        let updatedRobes = [6, 4, 2, 1].compactMap { updated.itemsByID[$0] }
        await store.receive(\.searchResponse) {
            $0.allResults = updatedRobes
            $0.visibleResultCount = updatedRobes.count
            $0.isSearching = false
        }
    }

    /// More matches than a page lists the first page only.
    @Test func resultsShowTheFirstPage() async {
        let clock = TestClock()
        let store = TestStore(
            initialState: ItemSearchFeature.State(loadState: .loaded, catalog: pagedCatalog)
        ) {
            ItemSearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.searchQueryChanged("道具")) {
            $0.query = "道具"
            $0.isSearching = true
        }
        await clock.advance(by: .milliseconds(300))
        await store.receive(\.searchResponse) {
            $0.allResults = self.pagedResults
            $0.visibleResultCount = 50
            $0.isSearching = false
        }

        #expect(store.state.results.map(\.id) == Array((71...120).reversed()))
        #expect(store.state.totalMatchCount == 120)
        #expect(store.state.hiddenResultCount == 70)
        #expect(store.state.canLoadMoreResults)
    }

    /// Each tap lists one more page, up to the last match.
    @Test func loadingMoreListsTheNextPage() async {
        let store = TestStore(
            initialState: ItemSearchFeature.State(
                loadState: .loaded,
                catalog: pagedCatalog,
                query: "道具",
                allResults: pagedResults,
                visibleResultCount: 50
            )
        ) {
            ItemSearchFeature()
        }

        await store.send(.loadMoreButtonTapped) {
            $0.visibleResultCount = 100
        }
        #expect(store.state.hiddenResultCount == 20)

        // The last page holds only the 20 matches left.
        await store.send(.loadMoreButtonTapped) {
            $0.visibleResultCount = 120
        }
        #expect(store.state.results.map(\.id) == Array((1...120).reversed()))
        #expect(store.state.hiddenResultCount == 0)
        #expect(!store.state.canLoadMoreResults)
    }

    /// With every match listed, loading more changes nothing.
    @Test func loadingMoreAfterTheLastPageDoesNothing() async {
        let store = TestStore(
            initialState: ItemSearchFeature.State(
                loadState: .loaded,
                catalog: pagedCatalog,
                query: "道具",
                allResults: pagedResults,
                visibleResultCount: 120
            )
        ) {
            ItemSearchFeature()
        }

        await store.send(.loadMoreButtonTapped)
    }

    /// 120 items, more than two pages, all named 「道具…」. A higher id has a higher item level,
    /// and every name starts with 「道具」, so searching for it lists them from id 120 down.
    private let pagedCatalog = ItemSearchFixture.catalog(
        items: (1...120).map { ItemSearchFixture.item(id: $0, name: "道具\($0)", ilvl: $0) }
    )

    /// What searching `pagedCatalog` for 「道具」 lists.
    private var pagedResults: [Item] {
        pagedCatalog.items.reversed()
    }
}
