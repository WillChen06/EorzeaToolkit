//
//  RelicWeaponClient.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/10/29.
//

import ComposableArchitecture

@DependencyClient
struct RelicWeaponClient: Sendable {
    var fetch: @Sendable () async throws -> [WeaponSeries]
}

extension RelicWeaponClient: TestDependencyKey {
    static let testValue = Self()
}

extension RelicWeaponClient: DependencyKey {
    static let liveValue = Self(
        fetch: {
            let data: RelicWeaponData = try LocalDataService.load("relic_weapons")
            return data.weaponSeriesList
        }
    )
}

extension DependencyValues {
    var relicWeapon: RelicWeaponClient {
        get { self[RelicWeaponClient.self] }
        set { self[RelicWeaponClient.self] = newValue }
    }
}
