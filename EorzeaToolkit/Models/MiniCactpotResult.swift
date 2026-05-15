import Foundation

struct MiniCactpotResult: Identifiable, Hashable {
    let line: MiniCactpotLine
    let expectedValue: Double

    var id: Int {
        line.id
    }
}
