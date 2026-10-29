//
//  RelicWeaponSeriesFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import Testing
import ComposableArchitecture

@testable import EorzeaToolkit

@MainActor
struct RelicWeaponSeriesFeatureTests {
    private let sample = WeaponSeries(
        id: "1",
        nameTw: "A",
        fullNameTw: "AAA",
        expansion:"",
        levelCap: 10,
        availableJobs: ["PLD", "MNK", "WAR"],
        stages: []
    )

    @Test(arguments: [
        (["PLD", "MNK"], "PLD"),
        ([], ""),
    ])
    func initSelectsFirstJob(jobs: [String], expectedJob: String) {
        let series = WeaponSeries(id: "1", nameTw: "A", fullNameTw: "AAA", expansion: "", levelCap: 10, availableJobs: jobs, stages: [])

        #expect(RelicWeaponSeriesFeature.State(series: series).selectedJob == expectedJob)
    }

    @Test func modeSelectedUpdatesMode() async {
        let store = TestStore(initialState: RelicWeaponSeriesFeature.State(series: sample)) {
            RelicWeaponSeriesFeature()
        }
        
        await store.send(.modeSelected(.tracking)) {
            $0.selectedMode = .tracking
        }
    }
    
    @Test func jobSelectedUpdatesJob() async {
        let store = TestStore(initialState: RelicWeaponSeriesFeature.State(series: sample)) {
            RelicWeaponSeriesFeature()
        }
        
        await store.send(.jobSelected("WAR")) {
            $0.selectedJob = "WAR"
        }
    }
}
