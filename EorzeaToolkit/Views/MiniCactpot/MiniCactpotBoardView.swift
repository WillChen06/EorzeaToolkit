import SwiftUI

struct MiniCactpotBoardView: View {
    let cells: [Int?]
    let highlightedLineID: Int?
    let cellAction: (Int) -> Void

    private let maxGridWidth: CGFloat = 340
    private let spacing: CGFloat = 10

    var body: some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(0..<5, id: \.self) { column in
                    if let line = topLine(for: column) {
                        MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: spacing) {
                    let line = MiniCactpotLine.all[row]
                    MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)

                    ForEach(0..<3, id: \.self) { column in
                        let cellIndex = row * 3 + column
                        MiniCactpotCellView(value: cells[cellIndex]) {
                            cellAction(cellIndex)
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }

                    Color.clear
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .frame(maxWidth: maxGridWidth)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func topLine(for column: Int) -> MiniCactpotLine? {
        switch column {
        case 0:
            MiniCactpotLine.all[6]
        case 1...3:
            MiniCactpotLine.all[column + 2]
        case 4:
            MiniCactpotLine.all[7]
        default:
            nil
        }
    }
}

#Preview {
    MiniCactpotBoardView(
        cells: [nil, nil, 6, nil, 7, nil, 9, nil, 3],
        highlightedLineID: 4
    ) { _ in }
    .padding()
}
