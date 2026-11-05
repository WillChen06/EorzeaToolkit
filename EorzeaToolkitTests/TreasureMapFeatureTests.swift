//
//  TreasureMapFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/4.
//

import Testing
import ComposableArchitecture
@testable import EorzeaToolkit

@MainActor
struct TreasureMapFeatureTests {
    private func makeLoadedStore(
        catalog: TreasureMapCatalog = TreasureMapFixture.catalog()
    ) -> TestStoreOf<TreasureMapFeature> {
        TestStore(initialState: TreasureMapFeature.State(loadState: .loaded(catalog))) {
            TreasureMapFeature()
        }
    }
    
    @Test func taskLoadsCatalog() async {
        let catalog = TreasureMapFixture.catalog()
        let store = TestStore(initialState: TreasureMapFeature.State()) {
            TreasureMapFeature()
        } withDependencies: {
            $0.treasureMap.fetch = {
                catalog
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded(catalog)
        }
    }
    
    @Test func taskFailureShowsError() async {
        let store = TestStore(initialState: TreasureMapFeature.State()) {
            TreasureMapFeature()
        } withDependencies: {
            $0.treasureMap.fetch = {
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
    
    @Test(arguments: [TreasureMapFeature.LoadState.loading, .loaded(TreasureMapFixture.catalog())])
    func taskDoesNothingWhenLoadingOrLoaded(loadState: TreasureMapFeature.LoadState) async {
        let store = TestStore(initialState: TreasureMapFeature.State(loadState: loadState)) {
            TreasureMapFeature()
        }
        
        await store.send(.task)
    }
    
    @Test func retriesAfterFailed() async {
        let catalog = TreasureMapFixture.catalog()
        let store = TestStore(
            initialState: TreasureMapFeature.State(loadState: .failed("x"))
        ) {
            TreasureMapFeature()
        } withDependencies: {
            $0.treasureMap.fetch = {
                catalog
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded(catalog)
        }
    }
    
    @Test func defaultOrderIsDescending() {
        let store = makeLoadedStore()
        #expect(store.state.displayedMaps.map(\.grade) == ["G6", "G5", "G4", "G3", "G2", "G1"])
    }
    
    @Test func sortButtonReversesOrder() async {
        let store = makeLoadedStore()
        
        await store.send(.sortButtonTapped) {
            $0.sortDirection = .ascending
        }
        
        #expect(store.state.displayedMaps.map(\.grade) == ["G1", "G2", "G3", "G4", "G5", "G6"])
    }
    
    @Test func togglingVersionUpdatesDisplayedMaps() async {
        let store = makeLoadedStore()
        await store.send(.majorVersionToggled(7)) {
            $0.filter.selectedMajorVersions = [7]
        }
        
        #expect(Set(store.state.displayedMaps.map(\.id)) == ["G4", "G5"])
    }
    
    @Test func togglingSameLevelTwiceDeselectsIt() async {
        let store = makeLoadedStore()
        
        await store.send(.levelToggled(90)) {
            $0.filter.selectedLevels = [90]
        }
        
        await store.send(.levelToggled(90)) {
            $0.filter.selectedLevels = []
        }
    }
    
    @Test func filterCountIsSelectedVersionsPlusLevels() async {
        let store = makeLoadedStore()
        
        await store.send(.levelToggled(90)) {
            $0.filter.selectedLevels = [90]
        }
        
        await store.send(.majorVersionToggled(7)) {
            $0.filter.selectedMajorVersions = [7]
        }
        
        await store.send(.levelToggled(80)) {
            $0.filter.selectedLevels = [80, 90]
        }
        
        await store.send(.majorVersionToggled(6)) {
            $0.filter.selectedMajorVersions = [6, 7]
        }

        #expect(store.state.activeFilterCount == 4)
    }
    
    @Test func clearingFiltersRestoresAllMaps() async {
        let store = makeLoadedStore()
        
        await store.send(.levelToggled(90)) {
            $0.filter.selectedLevels = [90]
        }
        
        await store.send(.majorVersionToggled(7)) {
            $0.filter.selectedMajorVersions = [7]
        }
        
        #expect(store.state.displayedMaps.isEmpty)
        
        await store.send(.clearFiltersButtonTapped) {
            $0.filter = TreasureMapFilter()
        }
        
        #expect(store.state.displayedMaps.count == TreasureMapFixture.filteringMaps.count)
    }
    
    @Test func clearingFiltersKeepsSortDirection() async {
        let store = makeLoadedStore()
        
        await store.send(.sortButtonTapped) {
            $0.sortDirection = .ascending
        }
        
        await store.send(.levelToggled(90)) {
            $0.filter.selectedLevels = [90]
        }
        
        await store.send(.majorVersionToggled(7)) {
            $0.filter.selectedMajorVersions = [7]
        }
        
        #expect(store.state.displayedMaps.isEmpty)
        
        await store.send(.clearFiltersButtonTapped) {
            $0.filter = TreasureMapFilter()
        }
        
        #expect(store.state.displayedMaps.count == TreasureMapFixture.filteringMaps.count)
    }
    
    @Test func closingFilterPopoverKeepsFilter() async {
        let store = makeLoadedStore()

        await store.send(.filterPresentationChanged(true)) {
            $0.isFilterPresented = true
        }
        await store.send(.majorVersionToggled(6)) {
            $0.filter.selectedMajorVersions = [6]
        }
        await store.send(.filterPresentationChanged(false)) {
            $0.isFilterPresented = false
        }

        #expect(Set(store.state.displayedMaps.map(\.id)) == ["G2", "G3"])  // 只剩 6.x 的圖
    }
    
    @Test func selectingMapSetsSelectedMap() async {
        let mapID = "G2"
        let store = makeLoadedStore()
        
        await store.send(.mapSelected(mapID)) {
            $0.selectedMapID = mapID
        }
        
        #expect(store.state.selectedMap?.id == mapID)
    }
    
    @Test func selectingUnknownMapHasNoSelectedMap() async {
        let store = makeLoadedStore()
        
        await store.send(.mapSelected("G2")) {
            $0.selectedMapID = "G2"
        }
        
        await store.send(.mapSelected("G10")) {
            $0.selectedMapID = nil
        }
    }
    
    @Test func deselectingMapClearsSelection() async {
        let mapID = "G2"
        let store = makeLoadedStore()
        
        await store.send(.mapSelected(mapID)) {
            $0.selectedMapID = mapID
        }
        
        #expect(store.state.selectedMap?.id == mapID)
        
        await store.send(.mapSelected(nil)) {
            $0.selectedMapID = nil
        }
        
        #expect(store.state.selectedMap == nil)
    }
    
    // MARK: Gathering Tests
    private let gatheringMap = TreasureMapFixture.map(gatheringNodes: [
        TreasureMapFixture.node(type: 0, zoneId: 100, mapId: 10, x: 12.3, y: 45.6, zoneName: "中拉諾西亞"),
        TreasureMapFixture.node(type: 2, zoneId: 200, mapId: 20, x: 7.8, y: 9.1, zoneName: "黑衣森林中央林區"),
    ])

    private var expectedGathering: GatheringNodesFeature.State {
        GatheringNodesFeature.State(nodes: gatheringMap.gatheringNodes, map: gatheringMap)
    }

    private func makeGatheringStore() -> TestStoreOf<TreasureMapFeature> {
        makeLoadedStore(catalog: TreasureMapFixture.catalog(maps: [gatheringMap]))
    }

    @Test func gatheringButtonPresentsTheMapsNodes() async {
        let store = makeGatheringStore()

        await store.send(.gatheringButtonTapped("G1")) {
            $0.gathering = expectedGathering
        }
    }

    @Test func gatheringButtonIgnoresUnknownMap() async {
        let store = makeLoadedStore()

        await store.send(.gatheringButtonTapped("G100"))
    }

    @Test func gatheringButtonDoesNothingBeforeCatalogLoads() async {
        let store = TestStore(initialState: TreasureMapFeature.State()) {
            TreasureMapFeature()
        }

        await store.send(.gatheringButtonTapped("G1"))
    }

    @Test func closeButtonDismissesGatheringSheet() async {
        let store = makeGatheringStore()

        await store.send(.gatheringButtonTapped("G1")) {
            $0.gathering = expectedGathering
        }
        
        await store.send(\.gathering.closeButtonTapped)
            
        await store.receive(\.gathering.dismiss) {
            $0.gathering = nil
        }
    }
}
