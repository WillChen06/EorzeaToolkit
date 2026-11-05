//
//  TreasureMapCatalogTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/3.
//

import Testing
@testable import EorzeaToolkit

struct TreasureMapCatalogTests {
    @Test func mapsKeepTheirOrderFromTheData() {
        let catalog = TreasureMapFixture.catalog(maps: [
            TreasureMapFixture.map(grade: "G3"),
            TreasureMapFixture.map(grade: "G1"),
            TreasureMapFixture.map(grade: "G2"),
        ])

        #expect(catalog.maps.map(\.id) == ["G3", "G1", "G2"])
    }
}
