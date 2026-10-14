import XCTest
@testable import EorzeaToolkit

/// SwiftUI's stepped `Slider` traps when its range has no width, which happened when the
/// minimum reached the top of the range or the maximum reached the bottom.
final class LevelRangeSlidersTests: XCTestCase {
    func testNoEquipLevelSliderRangeIsEmpty() {
        assertEverySliderRangeHasWidth(bounds: ItemFilter.defaultEquipLevelRange)
    }

    func testNoItemLevelSliderRangeIsEmpty() {
        assertEverySliderRangeHasWidth(bounds: ItemFilter.defaultIlvlRange)
    }

    func testEachSliderStopsAtTheOtherEnd() {
        let sliders = LevelRangeSliders(range: 80...90, bounds: 1...100)

        XCTAssertEqual(sliders.minimumRange, 1...90)
        XCTAssertEqual(sliders.maximumRange, 80...100)
        XCTAssertFalse(sliders.isMinimumDisabled)
        XCTAssertFalse(sliders.isMaximumDisabled)
    }

    func testARangeOfOneLevelInsideTheBoundsLeavesBothSlidersMovable() {
        let sliders = LevelRangeSliders(range: 80...80, bounds: 1...100)

        XCTAssertEqual(sliders.minimumRange, 1...80)
        XCTAssertEqual(sliders.maximumRange, 80...100)
        XCTAssertFalse(sliders.isMinimumDisabled)
        XCTAssertFalse(sliders.isMaximumDisabled)
    }

    func testTheMaximumIsDisabledAtTheTopWhenTheMinimumIsThere() {
        let sliders = LevelRangeSliders(range: 100...100, bounds: 1...100)

        XCTAssertEqual(sliders.maximumRange, 99...100)
        XCTAssertTrue(sliders.isMaximumDisabled)
        XCTAssertEqual(sliders.minimumRange, 1...100)
        XCTAssertFalse(sliders.isMinimumDisabled)
    }

    func testTheMinimumIsDisabledAtTheBottomWhenTheMaximumIsThere() {
        let sliders = LevelRangeSliders(range: 1...1, bounds: 1...100)

        XCTAssertEqual(sliders.minimumRange, 1...2)
        XCTAssertTrue(sliders.isMinimumDisabled)
        XCTAssertEqual(sliders.maximumRange, 1...100)
        XCTAssertFalse(sliders.isMaximumDisabled)
    }

    /// Every range inside the bounds gives both sliders some width, contains the value each
    /// slider shows, and disables a slider only when it has a single value to offer.
    private func assertEverySliderRangeHasWidth(
        bounds: ClosedRange<Int>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var failures: [ClosedRange<Int>] = []
        for lower in bounds {
            for upper in lower...bounds.upperBound {
                let range = lower...upper
                let sliders = LevelRangeSliders(range: range, bounds: bounds)
                let isValid = sliders.minimumRange.lowerBound < sliders.minimumRange.upperBound &&
                    sliders.maximumRange.lowerBound < sliders.maximumRange.upperBound &&
                    sliders.minimumRange.contains(lower) &&
                    sliders.maximumRange.contains(upper) &&
                    sliders.isMinimumDisabled == (upper == bounds.lowerBound) &&
                    sliders.isMaximumDisabled == (lower == bounds.upperBound)
                if !isValid {
                    failures.append(range)
                }
            }
        }

        XCTAssertTrue(failures.isEmpty, "slider ranges wrong for \(failures.prefix(5))", file: file, line: line)
    }
}
