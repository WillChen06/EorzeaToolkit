//
//  SkillRotationFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/9.
//

import Testing
import ComposableArchitecture
import Foundation

@testable import EorzeaToolkit

@MainActor
struct SkillRotationFeatureTests {
    private let paladinID = BattleActionFixture.paladin.id
    private let monkID = BattleActionFixture.monk.id
    
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
    
    @Test(arguments: [Optional(BattleActionFixture.monk.id), nil])
    func jobSelectedClearsTheSelection(jobID: Int?) async {
        let store = TestStore(
            initialState: SkillRotationFeature.State(
                jobs: [BattleActionFixture.paladin],
                editor: BattleActionFixture.editorState()
            )
        ) {
            SkillRotationFeature()
        }

        await store.send(.jobSelected(jobID)) {
            $0.editor = nil
        }
    }
    
    @Test func jobSelectedOpensTheEditorWithTheJobsRotations() async {
        let catalog = BattleActionFixture.catalog()
        let saved: [SkillRotationLevel: [RotationSlot]] = [
            .level90: [RotationSlot(id: UUID(100), action: BattleActionFixture.fastBlade)],
        ]
        let store = TestStore(
            initialState: SkillRotationFeature.State(
                jobs: IdentifiedArray(uniqueElements: catalog.jobs),
                tinctures: catalog.tinctures,
                tinctureStatJobs: catalog.tinctureStatJobs,
                rotationsByJobID: [paladinID: saved]
            )
        ) {
            SkillRotationFeature()
        }

        await store.send(.jobSelected(paladinID)) {
            $0.editor = SkillRotationEditorFeature.State(
                job: BattleActionFixture.paladin,
                rotationsByLevel: saved,
                tinctures: catalog.tinctures,
                tinctureStatJobs: catalog.tinctureStatJobs
            )
        }
    }

    // Selecting another job starts its editor over, so the level goes back to the default. The
    // view model kept the level when the iPad split view switched jobs.
    @Test func jobSelectedResetsTheLevelForAnotherJob() async {
        let catalog = BattleActionFixture.catalog()
        let store = TestStore(initialState: loadedState()) {
            SkillRotationFeature()
        }

        await store.send(.jobSelected(paladinID)) {
            $0.editor = SkillRotationEditorFeature.State(
                job: BattleActionFixture.paladin,
                tinctures: catalog.tinctures,
                tinctureStatJobs: catalog.tinctureStatJobs
            )
        }
        await store.send(.editor(.levelSelected(.level70))) {
            $0.editor?.selectedLevel = .level70
        }
        await store.send(.jobSelected(monkID)) {
            $0.editor = SkillRotationEditorFeature.State(
                job: BattleActionFixture.monk,
                tinctures: catalog.tinctures,
                tinctureStatJobs: catalog.tinctureStatJobs,
                selectedLevel: .level100
            )
        }
    }

    @Test func jobSelectedKeepsTheEditorWhenTheSameJobIsSelectedAgain() async {
        let catalog = BattleActionFixture.catalog()
        let store = TestStore(initialState: loadedState()) {
            SkillRotationFeature()
        }

        await store.send(.jobSelected(paladinID)) {
            $0.editor = SkillRotationEditorFeature.State(
                job: BattleActionFixture.paladin,
                tinctures: catalog.tinctures,
                tinctureStatJobs: catalog.tinctureStatJobs
            )
        }
        await store.send(.editor(.levelSelected(.level70))) {
            $0.editor?.selectedLevel = .level70
        }
        // No state change: the editor, and its level, stay as they are.
        await store.send(.jobSelected(paladinID))
    }

    // MARK: - Editor changes

    @Test func editorChangesUpdateTheCachedRotations() async {
        var state = loadedState()
        state.editor = BattleActionFixture.editorState()
        let store = TestStore(initialState: state) {
            SkillRotationFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.skillRotationPersistence.save = { _, _, _ in }
        }
        let added = RotationSlot(id: UUID(0), action: BattleActionFixture.fastBlade)

        await store.send(.editor(.actionAdded(BattleActionFixture.fastBlade))) {
            $0.editor?.rotationsByLevel = [.level100: [added]]
        }
        await store.receive(\.editor.delegate) {
            $0.rotationsByJobID = [paladinID: [.level100: [added]]]
        }
        await store.finish()

        #expect(store.state.savedLevels(for: paladinID) == [.level100])
    }

    // AC-7
    @Test func editorChangesLeaveOtherJobsCachedRotationsAlone() async {
        let monkSlot = RotationSlot(id: UUID(100), action: BattleActionFixture.bootshine)
        var state = loadedState()
        state.rotationsByJobID = [monkID: [.level50: [monkSlot]]]
        state.editor = BattleActionFixture.editorState()
        let store = TestStore(initialState: state) {
            SkillRotationFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.skillRotationPersistence.save = { _, _, _ in }
        }
        let added = RotationSlot(id: UUID(0), action: BattleActionFixture.fastBlade)

        // Only the paladin's entry changes; the store fails if the monk's does too.
        await store.send(.editor(.actionAdded(BattleActionFixture.fastBlade))) {
            $0.editor?.rotationsByLevel = [.level100: [added]]
        }
        await store.receive(\.editor.delegate) {
            $0.rotationsByJobID[paladinID] = [.level100: [added]]
        }
        await store.send(.editor(.clearTapped)) {
            $0.editor?.rotationsByLevel = [:]
        }
        await store.receive(\.editor.delegate) {
            $0.rotationsByJobID[paladinID] = nil
        }
        await store.finish()

        #expect(store.state.rotationsByJobID == [monkID: [.level50: [monkSlot]]])
    }

    @Test func clearingTheLastLevelRemovesTheJobFromTheCache() async {
        let slot = RotationSlot(id: UUID(100), action: BattleActionFixture.fastBlade)
        var state = loadedState()
        state.rotationsByJobID = [paladinID: [.level100: [slot]]]
        state.editor = BattleActionFixture.editorState(rotationsByLevel: [.level100: [slot]])
        let store = TestStore(initialState: state) {
            SkillRotationFeature()
        } withDependencies: {
            $0.skillRotationPersistence.save = { _, _, _ in }
        }

        await store.send(.editor(.clearTapped)) {
            $0.editor?.rotationsByLevel = [:]
        }
        // Not `[paladinID: [:]]`: a reload would not have the job either.
        await store.receive(\.editor.delegate) {
            $0.rotationsByJobID = [:]
        }
        await store.finish()
    }

    // MARK: - savedLevels

    @Test func savedLevelsListsLevelsWithSlotsInDisplayOrder() {
        let slot = RotationSlot(id: UUID(100), action: BattleActionFixture.fastBlade)
        let state = SkillRotationFeature.State(rotationsByJobID: [
            paladinID: [.level50: [slot], .level100: [slot], .level70: []],
        ])

        // `displayCases` lists the highest level first; an empty level is not saved.
        #expect(state.savedLevels(for: paladinID) == [.level100, .level50])
    }

    @Test func savedLevelsIsEmptyForAJobWithoutRotations() {
        let slot = RotationSlot(id: UUID(100), action: BattleActionFixture.fastBlade)
        let state = SkillRotationFeature.State(rotationsByJobID: [paladinID: [.level50: [slot]]])

        #expect(state.savedLevels(for: monkID).isEmpty)
    }

    // MARK: - Helpers

    /// The list after the catalog loaded with nothing saved and no job selected.
    private func loadedState() -> SkillRotationFeature.State {
        let catalog = BattleActionFixture.catalog()
        return SkillRotationFeature.State(
            loadState: .loaded,
            jobs: IdentifiedArray(uniqueElements: catalog.jobs),
            tinctures: catalog.tinctures,
            tinctureStatJobs: catalog.tinctureStatJobs
        )
    }
}
