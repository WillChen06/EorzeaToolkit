//
//  RelicWeaponFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import Testing
import ComposableArchitecture
import Foundation

@testable import EorzeaToolkit

struct FetchError: LocalizedError {
    var errorDescription: String? { "fetch failed" }
}

@MainActor
struct RelicWeaponFeatureTests {
    
    @Test func taskLoadsWeaponSeries() async {
        let sample: [WeaponSeries] = [
            WeaponSeries(id: "1", nameTw: "A", fullNameTw: "AAA", expansion: "", levelCap: 10, availableJobs: [], stages: [])
        ]
        
        let store = TestStore(initialState: RelicWeaponFeature.State()) {
            RelicWeaponFeature()
        } withDependencies: {
            $0.relicWeapon.fetch = { sample }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.weaponSeriesResponse.success) {
            $0.weaponSeriesList = IdentifiedArray(uniqueElements: sample)
            $0.loadState = .loaded
        }
    }
    
    @Test func taskFailureShowError() async {
        let store = TestStore(initialState: RelicWeaponFeature.State()) {
            RelicWeaponFeature()
        } withDependencies: {
            $0.relicWeapon.fetch = { throw FetchError() }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.weaponSeriesResponse.failure) {
            $0.loadState = .failed("fetch failed")
        }
    }
    
    @Test(arguments: [RelicWeaponFeature.LoadState.loading, .loaded])
    func taskDoesNothingWhenLoadingOrLoaded(loadState: RelicWeaponFeature.LoadState) async {
        let store = TestStore(initialState: RelicWeaponFeature.State(loadState: loadState)) {
            RelicWeaponFeature()
        }
        
        await store.send(.task)
    }
    
    @Test func testRetriesAfterFailed() async {
        let sample: [WeaponSeries] = [
            WeaponSeries(id: "1", nameTw: "A", fullNameTw: "AAA", expansion: "", levelCap: 10, availableJobs: [], stages: [])
        ]
        
        let store = TestStore(initialState: RelicWeaponFeature.State(loadState: .failed("x"))) {
            RelicWeaponFeature()
        } withDependencies: {
            $0.relicWeapon.fetch = { sample }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.weaponSeriesResponse.success) {
            $0.weaponSeriesList = IdentifiedArray(uniqueElements: sample)
            $0.loadState = .loaded
        }
    }
    
    @Test func seriesSelectionCreatesDetail() async {
        let sample = WeaponSeries(
            id: "1",
            nameTw: "A",
            fullNameTw: "AAA",
            expansion: "",
            levelCap: 10,
            availableJobs: ["PLD", "MNK", "WAR"],
            stages: []
        )
        
        let store = TestStore(initialState: RelicWeaponFeature.State(weaponSeriesList: [sample])) {
            RelicWeaponFeature()
        }
        
        await store.send(.seriesSelected("1")) {
            $0.seriesDetail = RelicWeaponSeriesFeature.State(series: sample)
        }
        await store.send(.seriesDetail(.modeSelected(.tracking))) {
            $0.seriesDetail?.selectedMode = .tracking
        }
        
        await store.send(.seriesSelected("not-exist")) {
            $0.seriesDetail = nil
        }
        
        await store.send(.seriesSelected("1")) {
            $0.seriesDetail = RelicWeaponSeriesFeature.State(series: sample)
        }
        
        await store.send(.seriesSelected(nil)) {
            $0.seriesDetail = nil
        }
    }
}
