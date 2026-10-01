import XCTest
@testable import EorzeaToolkit

final class GatheringNodeMapLayoutTests: XCTestCase {
    func testDefaultWidthThreshold() {
        XCTAssertFalse(layout(width: 575).isHorizontal)
        XCTAssertTrue(layout(width: 576).isHorizontal)
    }

    func testScaledWidthThresholdAndAccessibilityFallback() {
        XCTAssertFalse(layout(width: 855, minimumMap: 480, minimumInformation: 360).isHorizontal)
        XCTAssertTrue(layout(width: 856, minimumMap: 480, minimumInformation: 360).isHorizontal)
        XCTAssertFalse(layout(width: 2000, accessibility: true).isHorizontal)
    }

    func testHorizontalInformationWidthLimits() {
        XCTAssertEqual(layout(width: 576).informationSize.width, 240)
        XCTAssertEqual(layout(width: 2000).informationSize.width, 320)
        XCTAssertEqual(layout(width: 816).informationSize.width, 280)
    }

    func testVerticalMapUsesLocalHeightAndWidth() {
        XCTAssertEqual(layout(width: 400, height: 216).mapSize.height, 130)
        XCTAssertEqual(layout(width: 200, height: 1016).mapSize.height, 200)
        XCTAssertEqual(layout(width: 400, height: 8).mapSize.height, 0)
        XCTAssertEqual(layout(width: 400, height: 8).informationSize.height, 0)
    }

    func testPaneSizesConserveAvailableSpace() {
        for width: CGFloat in [0, 200, 575, 576, 1000] {
            for height: CGFloat in [0, 8, 16, 216, 1000] {
                for accessibility in [false, true] {
                    let policy = layout(width: width, height: height, accessibility: accessibility)
                    for size in [policy.mapSize, policy.informationSize] {
                        XCTAssertGreaterThanOrEqual(size.width, 0)
                        XCTAssertGreaterThanOrEqual(size.height, 0)
                        XCTAssertLessThanOrEqual(size.width, width)
                        XCTAssertLessThanOrEqual(size.height, height)
                    }
                    if policy.isHorizontal {
                        XCTAssertEqual(policy.mapSize.width + policy.spacing + policy.informationSize.width, width, accuracy: 0.0001)
                        XCTAssertEqual(policy.mapSize.height, height)
                        XCTAssertEqual(policy.informationSize.height, height)
                    } else {
                        XCTAssertEqual(policy.mapSize.height + policy.spacing + policy.informationSize.height, height, accuracy: 0.0001)
                        XCTAssertEqual(policy.mapSize.width, width)
                        XCTAssertEqual(policy.informationSize.width, width)
                    }
                }
            }
        }
    }

    func testSquareFitsViewportAndNegativeSizesAreClamped() {
        XCTAssertEqual(GatheringNodeMapLayout.squareSide(in: CGSize(width: 600, height: 200)), 200)
        XCTAssertEqual(GatheringNodeMapLayout.squareSide(in: CGSize(width: 200, height: 600)), 200)
        XCTAssertEqual(GatheringNodeMapLayout.squareSide(in: .zero), 0)
        let policy = layout(width: -10, height: -20)
        XCTAssertEqual(policy.mapSize, .zero)
        XCTAssertEqual(policy.informationSize, .zero)
    }

    func testProjectionPreservesSizeFactorAndMapScale() {
        for (factor, side, expectedX, expectedY): (Int?, CGFloat, CGFloat, CGFloat) in [
            (100, 410, 205, 102.5), (200, 410, 410, 205),
            (100, 820, 410, 205), (nil, 410, 205, 102.5)
        ] {
            let point = GatheringMapProjection.position(x: 21.5, y: 11.25, sizeFactor: factor, mapSize: side)
            XCTAssertEqual(point.x, expectedX, accuracy: 0.0001)
            XCTAssertEqual(point.y, expectedY, accuracy: 0.0001)
        }
        XCTAssertEqual(GatheringMapProjection.position(x: 1, y: 1, mapSize: 410), .zero)
        XCTAssertEqual(GatheringMapProjection.position(x: 0, y: 83, mapSize: 410), CGPoint(x: -10, y: 820))
    }

    private func layout(width: CGFloat, height: CGFloat = 600, minimumMap: CGFloat = 320,
                        minimumInformation: CGFloat = 240, accessibility: Bool = false) -> GatheringNodeMapLayout {
        GatheringNodeMapLayout(availableSize: CGSize(width: width, height: height),
                               minimumMapWidth: minimumMap, minimumInformationWidth: minimumInformation,
                               isAccessibilitySize: accessibility)
    }
}
