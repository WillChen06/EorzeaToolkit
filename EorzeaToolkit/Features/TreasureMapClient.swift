//
//  TreasureMapClient.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/3.
//

import ComposableArchitecture

@DependencyClient
struct TreasureMapClient: Sendable {
    var fetch: @Sendable () async throws -> TreasureMapCatalog
}

extension TreasureMapClient: TestDependencyKey {
    static let testValue = Self()
}

extension TreasureMapClient: DependencyKey {
    static let liveValue = Self(
        fetch: {
            let data: TreasureMapData = try LocalDataService.load("treasure_maps")
            return TreasureMapCatalog(maps: data.maps)
        }
    )
}

extension DependencyValues {
    var treasureMap: TreasureMapClient {
        get { self[TreasureMapClient.self] }
        set { self[TreasureMapClient.self] = newValue }
    }
}

struct TreasureMapCatalog: Equatable, Sendable {
    let maps: IdentifiedArrayOf<TreasureMap>

    init(maps: [TreasureMap]) {
        self.maps = IdentifiedArray(uniqueElements: maps)
    }
}
