//
//  RelicWeaponProgressClient.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import ComposableArchitecture
import SwiftData
import Foundation

@DependencyClient
struct RelicWeaponProgressClient: Sendable {
    var load: @Sendable (_ seriesID: String, _ job: String) async throws -> Set<Int>
    var save: @Sendable (_ seriesID: String, _ job: String, _ completedStageIndices: Set<Int>) async throws -> Void
}

extension RelicWeaponProgressClient: TestDependencyKey {
    static let testValue = Self()
}

extension RelicWeaponProgressClient: DependencyKey {
    static let liveValue = Self.live(container: PersistenceController.container)
    
    static let previewValue = Self.live(
        container: try! ModelContainer(
            for: RelicWeaponProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    )

    static func live(container: ModelContainer) -> Self {
        Self(
            load: { seriesID, job in
                try await MainActor.run {
                    let records = try container.mainContext.fetch(descriptor(seriesID: seriesID, job: job))
                    
                    return records.reduce(into: Set<Int>()) {
                        $0.formUnion($1.completedStageIndices)
                    }
                }
            },
            save: { seriesID, job, completedStageIndices in
                try await MainActor.run {
                    let context = container.mainContext
                    do {
                        let records = try context.fetch(descriptor(seriesID: seriesID, job: job))
                        let record: RelicWeaponProgress
                        if let existing = records.first {
                            record = existing
                        } else {
                            record = RelicWeaponProgress(seriesID: seriesID, job: job)
                            context.insert(record)
                        }
                        record.completedStageIndices = completedStageIndices.sorted()
                        for duplicate in records.dropFirst() {
                            context.delete(duplicate)
                        }
                        try context.save()
                    } catch {
                        context.rollback()
                        throw error
                    }
                }
            }
        )
    }
    
    private static func descriptor(seriesID: String, job: String) -> FetchDescriptor<RelicWeaponProgress> {
        FetchDescriptor(
            predicate: #Predicate<RelicWeaponProgress> { progress in
                progress.seriesID == seriesID && progress.job == job
            }
        )
    }
}

extension DependencyValues {
    var relicWeaponProgress: RelicWeaponProgressClient {
        get { self[RelicWeaponProgressClient.self] }
        set { self[RelicWeaponProgressClient.self] = newValue }
    }
}
