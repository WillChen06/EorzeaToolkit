import XCTest
@testable import EorzeaToolkit

final class MiniCactpotCalculatorTests: XCTestCase {
    private let accuracy = 0.000_001

    func testRejectsBoardsThatAreNotNineCells() {
        XCTAssertTrue(MiniCactpotCalculator.calculateResults(cells: []).isEmpty)
        XCTAssertTrue(MiniCactpotCalculator.calculateResults(cells: Array(repeating: nil, count: 8)).isEmpty)
        XCTAssertTrue(MiniCactpotCalculator.calculateResults(cells: Array(repeating: nil, count: 10)).isEmpty)
    }

    func testAlwaysReturnsEveryLine() {
        let results = MiniCactpotCalculator.calculateResults(cells: Array(repeating: nil, count: 9))

        XCTAssertEqual(results.count, MiniCactpotLine.all.count)
        XCTAssertEqual(Set(results.map(\.line.id)), Set(MiniCactpotLine.all.map(\.id)))
    }

    /// A fully revealed board has nothing left to average, so every line is worth its payout.
    func testFullBoardScoresEachLineAtItsPayout() {
        let results = MiniCactpotCalculator.calculateResults(cells: (1...9).map { $0 })
        let valuesByLine = Dictionary(uniqueKeysWithValues: results.map { ($0.line.id, $0.expectedValue) })

        // Rows 1/2/3, columns left/centre/right, then both diagonals.
        XCTAssertEqual(valuesByLine[0], 10000)  // 1+2+3
        XCTAssertEqual(valuesByLine[1], 180)    // 4+5+6
        XCTAssertEqual(valuesByLine[2], 3600)   // 7+8+9
        XCTAssertEqual(valuesByLine[3], 108)    // 1+4+7
        XCTAssertEqual(valuesByLine[4], 180)    // 2+5+8
        XCTAssertEqual(valuesByLine[5], 119)    // 3+6+9
        XCTAssertEqual(valuesByLine[6], 180)    // 1+5+9
        XCTAssertEqual(valuesByLine[7], 180)    // 3+5+7
    }

    func testResultsAreSortedByExpectedValueDescending() {
        let results = MiniCactpotCalculator.calculateResults(cells: (1...9).map { $0 })

        XCTAssertEqual(results.map(\.line.id), [0, 2, 1, 4, 6, 7, 5, 3])
        XCTAssertEqual(results.map(\.expectedValue), results.map(\.expectedValue).sorted(by: >))
    }

    /// An empty board is symmetric: every line averages the same, so only the tie-break
    /// on line id decides the order. This is the case that would silently regress if the
    /// sort dropped its secondary comparison.
    func testEqualExpectedValuesBreakTiesOnLineID() {
        let results = MiniCactpotCalculator.calculateResults(cells: Array(repeating: nil, count: 9))

        XCTAssertEqual(results.map(\.line.id), Array(0..<MiniCactpotLine.all.count))

        // Mean payout over all 84 three-number combinations of 1...9.
        for result in results {
            XCTAssertEqual(result.expectedValue, 360.345_238_095_238_1, accuracy: accuracy)
        }
    }

    func testPartiallyRevealedLinesAverageOverTheRemainingNumbers() throws {
        var cells: [Int?] = Array(repeating: nil, count: 9)
        cells[0] = 1

        let results = MiniCactpotCalculator.calculateResults(cells: cells)
        let valuesByLine = Dictionary(uniqueKeysWithValues: results.map { ($0.line.id, $0.expectedValue) })

        // The three lines through cell 0 average payout[1 + a + b] over the 28 pairs from 2...9.
        for lineID in [0, 3, 6] {
            XCTAssertEqual(try XCTUnwrap(valuesByLine[lineID]), 528.75, accuracy: accuracy)
        }

        // The other five average payout[a + b + c] over the 56 triples from 2...9.
        for lineID in [1, 2, 4, 5, 7] {
            XCTAssertEqual(try XCTUnwrap(valuesByLine[lineID]), 276.142_857_142_857_1, accuracy: accuracy)
        }
    }

    func testLineWithOneUnknownAveragesOverSingleNumbers() throws {
        var cells: [Int?] = Array(repeating: nil, count: 9)
        cells[0] = 1
        cells[1] = 2

        let results = MiniCactpotCalculator.calculateResults(cells: cells)
        let topRow = try XCTUnwrap(results.first { $0.line.id == 0 })

        // Mean of payout[3 + r] for r in 3...9.
        XCTAssertEqual(topRow.expectedValue, 1650.857_142_857_143, accuracy: accuracy)
    }

    /// Every reachable three-number sum is 6...24, so no line should ever fall through
    /// to the `payout[...] ?? 0` default.
    func testPayoutTableCoversEveryReachableSum() {
        for sum in 6...24 {
            XCTAssertNotNil(MiniCactpotCalculator.payout[sum], "missing payout for line sum \(sum)")
        }

        XCTAssertEqual(MiniCactpotCalculator.payout.count, 19)
    }
}
