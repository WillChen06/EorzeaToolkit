import Foundation

enum MiniCactpotCalculator {
    static let payout: [Int: Int] = [
        6: 10000,
        7: 36,
        8: 720,
        9: 360,
        10: 80,
        11: 252,
        12: 108,
        13: 72,
        14: 54,
        15: 180,
        16: 72,
        17: 180,
        18: 119,
        19: 36,
        20: 306,
        21: 1080,
        22: 144,
        23: 1800,
        24: 3600
    ]

    static func calculateResults(cells: [Int?]) -> [MiniCactpotResult] {
        guard cells.count == 9 else {
            return []
        }

        let usedNumbers = Set(cells.compactMap { $0 })
        let remainingNumbers = (1...9).filter { !usedNumbers.contains($0) }

        return MiniCactpotLine.all
            .map { line in
                MiniCactpotResult(
                    line: line,
                    expectedValue: expectedValue(
                        for: line,
                        cells: cells,
                        remainingNumbers: remainingNumbers
                    )
                )
            }
            .sorted { lhs, rhs in
                if lhs.expectedValue == rhs.expectedValue {
                    return lhs.line.id < rhs.line.id
                }

                return lhs.expectedValue > rhs.expectedValue
            }
    }

    private static func expectedValue(
        for line: MiniCactpotLine,
        cells: [Int?],
        remainingNumbers: [Int]
    ) -> Double {
        let knownNumbers = line.indices.compactMap { cells[$0] }
        let knownSum = knownNumbers.reduce(0, +)
        let unknownCount = line.indices.count - knownNumbers.count

        guard unknownCount > 0 else {
            return Double(payout[knownSum] ?? 0)
        }

        let possibleNumbers = combinations(remainingNumbers, choose: unknownCount)
        guard !possibleNumbers.isEmpty else {
            return 0
        }

        let totalPayout = possibleNumbers.reduce(0) { sum, numbers in
            let lineSum = knownSum + numbers.reduce(0, +)
            return sum + (payout[lineSum] ?? 0)
        }

        return Double(totalPayout) / Double(possibleNumbers.count)
    }

    private static func combinations(_ values: [Int], choose count: Int) -> [[Int]] {
        guard count > 0 else {
            return [[]]
        }

        guard count <= values.count else {
            return []
        }

        guard count < values.count else {
            return [values]
        }

        var results: [[Int]] = []

        for index in values.indices {
            let remainingCount = values.distance(from: index, to: values.endIndex) - 1
            guard remainingCount >= count - 1 else {
                break
            }

            let nextIndex = values.index(after: index)
            let suffix = Array(values[nextIndex...])
            for combination in combinations(suffix, choose: count - 1) {
                results.append([values[index]] + combination)
            }
        }

        return results
    }
}
