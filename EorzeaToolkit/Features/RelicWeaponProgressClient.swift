//
//  RelicWeaponProgressClient.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import ComposableArchitecture

@DependencyClient
struct RelicWeaponProgressClient: Sendable {
    var load: @Sendable (_ seriesID: String, _ job: String) async throws -> Set<Int>
    var save: @Sendable (_ seriesID: String, _ job: String, _ completedStageIndices: Set<Int>) async throws -> Void
}

extension RelicWeaponProgressClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var relicWeaponProgress: RelicWeaponProgressClient {
        get { self[RelicWeaponProgressClient.self] }
        set { self[RelicWeaponProgressClient.self] = newValue }
    }
}
