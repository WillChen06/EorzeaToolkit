//
//  RelicWeaponProgressClientTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/10/30.
//

import Testing
import SwiftData

@testable import EorzeaToolkit

@MainActor
struct RelicWeaponProgressClientTests {
    private let container: ModelContainer
    private let client: RelicWeaponProgressClient
    
    init() throws {
        container = try ModelContainer(
            for: RelicWeaponProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        client = .live(container: container)
    }

    @Test func loadReturnsEmptyWhenNothingSaved() async throws {
        let indices = try await client.load(seriesID: "1", job: "PLD")
        #expect(indices.isEmpty)
    }
    
    @Test func saveThenLoadRoundTrips() async throws {
        try await client.save(seriesID: "1", job: "PLD", completedStageIndices: [1, 3])
        #expect(try await client.load(seriesID: "1", job: "PLD") == [1, 3])
    }
    
    @Test func loadMergesDuplicatedRecords() async throws {
        container.mainContext.insert(RelicWeaponProgress(seriesID: "1", job: "PLD", completedStageIndices: [1]))
        container.mainContext.insert(RelicWeaponProgress(seriesID: "1", job: "PLD", completedStageIndices: [2]))
        
        let indices = try await client.load(seriesID: "1", job: "PLD")
        
        #expect(indices == [1, 2])
    }
    
    @Test func saveDeletesDuplicatedRecords() async throws {
        container.mainContext.insert(RelicWeaponProgress(seriesID: "1", job: "PLD", completedStageIndices: [1]))
        container.mainContext.insert(RelicWeaponProgress(seriesID: "1", job: "PLD", completedStageIndices: [2]))
        try await client.save(seriesID: "1", job: "PLD", completedStageIndices: [3])
        
        let records = try container.mainContext.fetch(FetchDescriptor<RelicWeaponProgress>())
        
        #expect(records.count == 1)
        #expect(records.first?.completedStageIndices == [3])
    }
    
    @Test func jobsAreStoredSeparately() async throws {
        try await client.save(seriesID: "1", job: "PLD", completedStageIndices: [1, 3])
        try await client.save(seriesID: "1", job: "MNK", completedStageIndices: [2])
        #expect(try await client.load(seriesID: "1", job: "PLD") == [1, 3])
        #expect(try await client.load(seriesID: "1", job: "MNK") == [2])
    }
    
    @Test func saveOverwritesExistingRecord() async throws {
        try await client.save(seriesID: "1", job: "PLD", completedStageIndices: [1, 3])
        try await client.save(seriesID: "1", job: "PLD", completedStageIndices: [2])

        let records = try container.mainContext.fetch(FetchDescriptor<RelicWeaponProgress>())

        #expect(records.count == 1)
        #expect(records.first?.completedStageIndices == [2])
    }
}
