//
//  SkillRotationCatalogClient.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/6.
//

import ComposableArchitecture

@DependencyClient
struct SkillRotationCatalogClient: Sendable {
    var fetch: @Sendable () async throws -> BattleActionsData
}

extension SkillRotationCatalogClient: TestDependencyKey {
    static let testValue = Self()
}

extension SkillRotationCatalogClient: DependencyKey {
    static let liveValue = Self(
        fetch: { try LocalDataService.load("battle_actions") }
    )
}

extension DependencyValues {
    var skillRotationCatalog: SkillRotationCatalogClient {
        get { self[SkillRotationCatalogClient.self] }
        set { self[SkillRotationCatalogClient.self] = newValue }
    }
}
