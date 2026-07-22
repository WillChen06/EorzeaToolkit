import Foundation

struct MiniCactpotLine: Identifiable, Hashable {
    let id: Int
    let nameKey: String
    let indices: [Int]
    let arrowSymbol: String

    static let all: [MiniCactpotLine] = [
        MiniCactpotLine(id: 0, nameKey: "miniCactpot.line.firstRow", indices: [0, 1, 2], arrowSymbol: "→"),
        MiniCactpotLine(id: 1, nameKey: "miniCactpot.line.secondRow", indices: [3, 4, 5], arrowSymbol: "→"),
        MiniCactpotLine(id: 2, nameKey: "miniCactpot.line.thirdRow", indices: [6, 7, 8], arrowSymbol: "→"),
        MiniCactpotLine(id: 3, nameKey: "miniCactpot.line.leftColumn", indices: [0, 3, 6], arrowSymbol: "↓"),
        MiniCactpotLine(id: 4, nameKey: "miniCactpot.line.centerColumn", indices: [1, 4, 7], arrowSymbol: "↓"),
        MiniCactpotLine(id: 5, nameKey: "miniCactpot.line.rightColumn", indices: [2, 5, 8], arrowSymbol: "↓"),
        MiniCactpotLine(id: 6, nameKey: "miniCactpot.line.downDiagonal", indices: [0, 4, 8], arrowSymbol: "↘"),
        MiniCactpotLine(id: 7, nameKey: "miniCactpot.line.upDiagonal", indices: [2, 4, 6], arrowSymbol: "↙")
    ]
}
