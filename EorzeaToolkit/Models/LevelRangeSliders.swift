//
//  LevelRangeSliders.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/11.
//

/// What the minimum and maximum sliders of a level range filter can move across.
///
/// Each slider stops at the other end of the range. When that leaves a slider only one value,
/// because the minimum is at the top or the maximum at the bottom, it is disabled and kept one
/// step wide: SwiftUI's stepped `Slider` traps on a range with no width.
struct LevelRangeSliders: Equatable, Sendable {
    let minimumRange: ClosedRange<Int>
    let maximumRange: ClosedRange<Int>
    let isMinimumDisabled: Bool
    let isMaximumDisabled: Bool

    /// `bounds` must span at least two levels, and `range` must lie inside it.
    init(range: ClosedRange<Int>, bounds: ClosedRange<Int>) {
        minimumRange = bounds.lowerBound...max(range.upperBound, bounds.lowerBound + 1)
        maximumRange = min(range.lowerBound, bounds.upperBound - 1)...bounds.upperBound
        isMinimumDisabled = range.upperBound == bounds.lowerBound
        isMaximumDisabled = range.lowerBound == bounds.upperBound
    }
}
