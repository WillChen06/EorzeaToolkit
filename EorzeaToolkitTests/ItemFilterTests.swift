//
//  ItemFilterTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/13.
//

import Testing
@testable import EorzeaToolkit

/// The filter sheet's level sliders move each end of a range through these methods. An end
/// stays within the full range and never passes the other end.
struct ItemFilterTests {
    // MARK: - Equip level (1...100)

    @Test func anEquipLevelRangeWithinTheFullRangeIsKept() {
        var filter = ItemFilter()

        filter.setMaximumEquipLevel(90)
        filter.setMinimumEquipLevel(80)

        #expect(filter.equipLevelRange == 80...90)
        #expect(filter.isActive)
    }

    @Test func theMinimumEquipLevelCannotPassTheMaximum() {
        var filter = ItemFilter()

        filter.setMaximumEquipLevel(80)
        filter.setMinimumEquipLevel(90)

        #expect(filter.equipLevelRange == 80...80)
    }

    @Test func theMaximumEquipLevelCannotFallBelowTheMinimum() {
        var filter = ItemFilter()

        filter.setMinimumEquipLevel(80)
        filter.setMaximumEquipLevel(70)

        #expect(filter.equipLevelRange == 80...80)
    }

    @Test func equipLevelsOutsideTheFullRangeAreClamped() {
        var filter = ItemFilter()

        filter.setMinimumEquipLevel(0)
        filter.setMaximumEquipLevel(120)

        #expect(filter.equipLevelRange == ItemFilter.defaultEquipLevelRange)
        #expect(!filter.isActive)
    }

    // MARK: - Item level (1...795)

    @Test func anItemLevelRangeWithinTheFullRangeIsKept() {
        var filter = ItemFilter()

        filter.setMaximumItemLevel(700)
        filter.setMinimumItemLevel(600)

        #expect(filter.ilvlRange == 600...700)
        #expect(filter.isActive)
    }

    @Test func theMinimumItemLevelCannotPassTheMaximum() {
        var filter = ItemFilter()

        filter.setMaximumItemLevel(600)
        filter.setMinimumItemLevel(700)

        #expect(filter.ilvlRange == 600...600)
    }

    @Test func theMaximumItemLevelCannotFallBelowTheMinimum() {
        var filter = ItemFilter()

        filter.setMinimumItemLevel(600)
        filter.setMaximumItemLevel(500)

        #expect(filter.ilvlRange == 600...600)
    }

    @Test func itemLevelsOutsideTheFullRangeAreClamped() {
        var filter = ItemFilter()

        filter.setMinimumItemLevel(0)
        filter.setMaximumItemLevel(999)

        #expect(filter.ilvlRange == ItemFilter.defaultIlvlRange)
        #expect(!filter.isActive)
    }

    // MARK: - Each range on its own

    /// Moving one range leaves the other one, and the rest of the filter, as they were.
    @Test func eachRangeMovesOnItsOwn() {
        var filter = ItemFilter()

        filter.setMinimumItemLevel(600)
        #expect(filter.equipLevelRange == ItemFilter.defaultEquipLevelRange)

        filter.setMaximumEquipLevel(90)
        #expect(filter.ilvlRange == 600...ItemFilter.defaultIlvlRange.upperBound)

        var expected = ItemFilter()
        expected.ilvlRange = 600...795
        expected.equipLevelRange = 1...90
        #expect(filter == expected)
    }
}
