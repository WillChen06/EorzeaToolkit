//
//  RelicWeaponSeriesFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import Testing
import ComposableArchitecture
import Foundation

@testable import EorzeaToolkit

private struct ProgressError: LocalizedError {
    var errorDescription: String? { "fetch progress failed" }
}

private struct SaveProgressError: LocalizedError {
    var errorDescription: String? { "save progress failed" }
}

@MainActor
struct RelicWeaponSeriesFeatureTests {
    private let sample = WeaponSeries(
        id: "1",
        nameTw: "A",
        fullNameTw: "AAA",
        expansion: "",
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
    
    @Test func taskLoadsProgress() async {
        let store = TestStore(initialState: RelicWeaponSeriesFeature.State(series: sample)) {
            RelicWeaponSeriesFeature()
        } withDependencies: {
            $0.relicWeaponProgress.load = { _, _ in [1] }
        }
        
        await store.send(.task)
        
        await store.receive(\.progressResponse.success) {
            $0.completedStageIndices = [1]
            $0.isProgressLoaded = true
        }
    }
    
    @Test func loadFailureBlocksToggling() async {
        let store = TestStore(initialState: RelicWeaponSeriesFeature.State(series: sample)) {
            RelicWeaponSeriesFeature()
        } withDependencies: {
            $0.relicWeaponProgress.load = { _, _ in throw ProgressError() }
        }
        
        await store.send(.task)
        
        await store.receive(\.progressResponse.failure)
        
        await store.send(.stageToggled(1))
    }
    
    @Test func taskDoesNothingWhenLoaded() async {
        let store = TestStore(initialState: RelicWeaponSeriesFeature.State(series: sample)) {
            RelicWeaponSeriesFeature()
        } withDependencies: {
            $0.relicWeaponProgress.load = { _, _ in [1] }
        }
        
        await store.send(.task)
        
        await store.receive(\.progressResponse.success) {
            $0.completedStageIndices = [1]
            $0.isProgressLoaded = true
        }
        
        await store.send(.task)
    }

    @Test func stageToggledSavesProgress() async {
        let saved = LockIsolated<[Set<Int>]>([])
        let store = TestStore(initialState: RelicWeaponSeriesFeature.State(series: sample)) {
            RelicWeaponSeriesFeature()
        } withDependencies: {
            $0.relicWeaponProgress.load = { _, _ in [1, 2, 3] }
            $0.relicWeaponProgress.save = { seriesID, job, indices in
                #expect(seriesID == "1")
                #expect(job == "PLD")
                saved.withValue { $0.append(indices) }
            }
        }
        
        await store.send(.task)
        
        await store.receive(\.progressResponse.success) {
            $0.completedStageIndices = [1, 2, 3]
            $0.isProgressLoaded = true
        }
        
        await store.send(.stageToggled(2)) {
            $0.completedStageIndices = [1, 3]
        }

        await store.send(.stageToggled(2)) {
            $0.completedStageIndices = [1, 2, 3]
        }

        #expect(saved.value == [[1, 3], [1, 2, 3]])
    }
    
    @Test func saveFailureReloadsProgress() async {
        let store = TestStore(initialState: RelicWeaponSeriesFeature.State(series: sample)) {
            RelicWeaponSeriesFeature()
        } withDependencies: {
            $0.relicWeaponProgress.load = { _, _ in [1, 2, 3] }
            $0.relicWeaponProgress.save = { _, _, _ in throw SaveProgressError() }
        }
        
        await store.send(.task)
        
        await store.receive(\.progressResponse.success) {
            $0.completedStageIndices = [1, 2, 3]
            $0.isProgressLoaded = true
        }
        
        await store.send(.stageToggled(2)) {
            $0.completedStageIndices = [1, 3]
        }
        
        await store.receive(\.saveFailed) {
            $0.isProgressLoaded = false
        }
        
        await store.receive(\.progressResponse.success) {
            $0.completedStageIndices = [1, 2, 3]
            $0.isProgressLoaded = true
        }
    }
    
    @Test func jobSelectedLoadsItsProgress() async {
        let store = TestStore(initialState: RelicWeaponSeriesFeature.State(series: sample)) {
            RelicWeaponSeriesFeature()
        } withDependencies: {
            $0.relicWeaponProgress.load = { _, job in job == "MNK" ? [1, 2] : [] }
        }
        
        await store.send(.jobSelected("MNK")) {
            $0.selectedJob = "MNK"
            $0.completedStageIndices = []
            $0.isProgressLoaded = false
        }
        
        await store.receive(\.progressResponse.success) {
            $0.completedStageIndices = [1, 2]
            $0.isProgressLoaded = true
        }
    }
}
