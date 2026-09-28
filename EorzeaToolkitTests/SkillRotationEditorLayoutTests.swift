import XCTest
@testable import EorzeaToolkit

final class SkillRotationEditorLayoutTests: XCTestCase {
    func testUsesHorizontalLayoutAtExactWidthThreshold() {
        let layout = makeLayout(width: 601)
        XCTAssertTrue(layout.isHorizontal)
        XCTAssertEqual(layout.rotationSize, CGSize(width: 300, height: 801))
        XCTAssertEqual(layout.selectionSize, layout.rotationSize)
        XCTAssertEqual(layout.dividerSize, CGSize(width: 1, height: 801))
    }

    func testUsesVerticalLayoutBelowWidthThreshold() {
        for width: CGFloat in [320, 390, 600] {
            let layout = makeLayout(width: width)
            XCTAssertFalse(layout.isHorizontal)
            XCTAssertEqual(layout.rotationSize.width, width)
            XCTAssertEqual(layout.selectionSize.width, width)
        }
    }

    func testAccessibilitySizeAlwaysUsesVerticalLayout() {
        for width: CGFloat in [390, 601, 1200] {
            XCTAssertFalse(makeLayout(width: width, accessibility: true).isHorizontal)
        }
    }

    func testScaledMinimumPaneWidthMovesThreshold() {
        XCTAssertFalse(makeLayout(width: 720, minimumPaneWidth: 360).isHorizontal)
        XCTAssertTrue(makeLayout(width: 721, minimumPaneWidth: 360).isHorizontal)
    }

    func testVerticalRotationHeightUsesLocalAvailableHeight() {
        let tall = makeLayout(width: 390)
        XCTAssertEqual(tall.rotationSize.height, 320)
        XCTAssertEqual(tall.selectionSize.height, 480)
        let short = makeLayout(width: 390, height: 201)
        XCTAssertEqual(short.rotationSize.height, 80)
        XCTAssertEqual(short.selectionSize.height, 120)
    }

    func testVerticalPaneAllocationDoesNotExceedLocalHeight() {
        for height: CGFloat in [0, 0.5, 1, 100, 301, 801] {
            let layout = makeLayout(width: 390, height: height)
            XCTAssertGreaterThanOrEqual(layout.rotationSize.height, 0)
            XCTAssertGreaterThanOrEqual(layout.selectionSize.height, 0)
            XCTAssertEqual(
                layout.rotationSize.height + layout.selectionSize.height + layout.dividerSize.height,
                height, accuracy: 0.001
            )
        }
    }

    private func makeLayout(
        width: CGFloat,
        height: CGFloat = 801,
        minimumPaneWidth: CGFloat = 300,
        accessibility: Bool = false
    ) -> SkillRotationEditorLayout {
        SkillRotationEditorLayout(
            size: CGSize(width: width, height: height),
            minimumPaneWidth: minimumPaneWidth,
            isAccessibilitySize: accessibility
        )
    }
}
