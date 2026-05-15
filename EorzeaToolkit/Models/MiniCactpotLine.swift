import Foundation

struct MiniCactpotLine: Identifiable, Hashable {
    let id: Int
    let name: String
    let indices: [Int]
    let arrowSymbol: String

    static let all: [MiniCactpotLine] = [
        MiniCactpotLine(id: 0, name: "第一橫列", indices: [0, 1, 2], arrowSymbol: "←"),
        MiniCactpotLine(id: 1, name: "第二橫列", indices: [3, 4, 5], arrowSymbol: "←"),
        MiniCactpotLine(id: 2, name: "第三橫列", indices: [6, 7, 8], arrowSymbol: "←"),
        MiniCactpotLine(id: 3, name: "左直行", indices: [0, 3, 6], arrowSymbol: "↓"),
        MiniCactpotLine(id: 4, name: "中直行", indices: [1, 4, 7], arrowSymbol: "↓"),
        MiniCactpotLine(id: 5, name: "右直行", indices: [2, 5, 8], arrowSymbol: "↓"),
        MiniCactpotLine(id: 6, name: "左上到右下", indices: [0, 4, 8], arrowSymbol: "↘"),
        MiniCactpotLine(id: 7, name: "右上到左下", indices: [2, 4, 6], arrowSymbol: "↙")
    ]
}
