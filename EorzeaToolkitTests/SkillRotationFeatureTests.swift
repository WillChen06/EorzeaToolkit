//
//  SkillRotationFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/9.
//

import Testing
import ComposableArchitecture

@testable import EorzeaToolkit

@MainActor
struct SkillRotationFeatureTests {
    private let paladinID = BattleActionFixture.paladin.id
    
    @Test func taskLoadsCatalogWithoutStoredSlots() async {
        let sample = BattleActionFixture.catalog()
        
        let store = TestStore(initialState: SkillRotationFeature.State()) {
            SkillRotationFeature()
        } withDependencies: {
            $0.skillRotationCatalog.fetch = { sample }
            
            $0.skillRotationPersistence.load = { [] }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.loadResponse.success) {
            $0.jobs = IdentifiedArray(uniqueElements: sample.jobs)
            $0.tinctures = sample.tinctures
            $0.tinctureStatJobs = sample.tinctureStatJobs
            $0.rotationsByJobID = [:]
            $0.loadState = .loaded
        }
    }
    
    @Test func taskLoadsCatalogAndStoredSlots() async {
        let sample = BattleActionFixture.catalog()
        let action = RotationSlot(action: BattleActionFixture.fastBlade)
        let tincture = RotationSlot(tincture: BattleActionFixture.strengthTincture)
        let storedSlot = [
            StoredSlot(
                id: action.id, jobID: paladinID, level: 100, position: 0,
                reference: .action(BattleActionFixture.fastBlade.id)
            ),
            StoredSlot(
                id: tincture.id, jobID: paladinID, level: 100, position: 1,
                reference: .tincture(BattleActionFixture.strengthTincture.id)
            ),
        ]
        
        let store = TestStore(initialState: SkillRotationFeature.State()) {
            SkillRotationFeature()
        } withDependencies: {
            $0.skillRotationCatalog.fetch = { sample }
            
            $0.skillRotationPersistence.load = { storedSlot }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.loadResponse.success) {
            $0.jobs = IdentifiedArray(uniqueElements: sample.jobs)
            $0.tinctures = sample.tinctures
            $0.tinctureStatJobs = sample.tinctureStatJobs
            $0.rotationsByJobID = [
                paladinID: [.level100: [action, tincture]],
            ]
            $0.loadState = .loaded
        }
    }

    @Test func taskShowsErrorWhenCatalogFails() async {
        let store = TestStore(initialState: SkillRotationFeature.State()) {
            SkillRotationFeature()
        } withDependencies: {
            $0.skillRotationCatalog.fetch = { throw FetchError() }
            
            $0.skillRotationPersistence.load = { [] }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.loadResponse.failure) {
            $0.loadState = .failed("fetch failed")
        }
    }
    
    @Test func taskFailsWhenStoredSlotsFailToLoad() async {
        let store = TestStore(initialState: SkillRotationFeature.State()) {
            SkillRotationFeature()
        } withDependencies: {
            $0.skillRotationCatalog.fetch = { BattleActionFixture.catalog() }
            $0.skillRotationPersistence.load = { throw FetchError() }
        }

        await store.send(.task) {
            $0.loadState = .loading
        }
        await store.receive(\.loadResponse.failure) {
            $0.loadState = .failed("fetch failed")
        }
    }
    
    @Test(arguments: [SkillRotationFeature.LoadState.loading, .loaded])
    func taskDoesNothingWhenLoadingOrLoaded(loadState: SkillRotationFeature.LoadState) async {
        let store = TestStore(initialState: SkillRotationFeature.State(loadState: loadState)) {
            SkillRotationFeature()
        }
        
        await store.send(.task)
    }
    
    @Test func taskRetriesAfterFailure() async {
        let sample = BattleActionFixture.catalog()
        let store = TestStore(initialState: SkillRotationFeature.State(loadState: .failed("x"))) {
            SkillRotationFeature()
        } withDependencies: {
            $0.skillRotationCatalog.fetch = { sample }
            
            $0.skillRotationPersistence.load = { [] }
        }
        
        store.exhaustivity = .off

        await store.send(.task) {
            $0.loadState = .loading
        }
        await store.receive(\.loadResponse.success) {
            $0.loadState = .loaded
        }
    }
    
    @Test func jobSelectedSelectsAJobInTheCatalog() async {
        let paladin = BattleActionFixture.paladin
        let jobs = IdentifiedArray(uniqueElements: [paladin])
        let store = TestStore(initialState: SkillRotationFeature.State(jobs: jobs)) {
            SkillRotationFeature()
        }
        
        await store.send(.jobSelected(paladinID)) {
            $0.selectedJobID = paladinID
        }
    }
    
    @Test(arguments: [Optional(BattleActionFixture.monk.id), nil])
    func jobSelectedClearsTheSelection(jobID: Int?) async {
        var state = SkillRotationFeature.State(jobs: [BattleActionFixture.paladin])
        state.selectedJobID = paladinID
        let store = TestStore(initialState: state) {
            SkillRotationFeature()
        }

        await store.send(.jobSelected(jobID)) {
            $0.selectedJobID = nil
        }
    }
}
