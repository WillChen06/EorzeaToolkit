import SwiftUI

struct MiniCactpotBoardView: View {
    let cells: [Int?]
    let highlightedLineID: Int?
    let cellAction: (Int) -> Void

    private let maxGridWidth: CGFloat = 340
    private let spacing: CGFloat = 10

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: 5)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<20, id: \.self) { index in
                if index < 5 {
                    if let line = topLine(for: index) {
                        MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                } else if boardColumn(for: index) == 0 {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                } else if boardColumn(for: index) == 4 {
                    let line = MiniCactpotLine.all[boardRow(for: index)]
                    MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                } else {
                    let cellIndex = boardRow(for: index) * 3 + boardColumn(for: index) - 1
                    MiniCactpotCellView(value: cells[cellIndex]) {
                        cellAction(cellIndex)
                    }
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

    private func boardRow(for gridIndex: Int) -> Int {
        (gridIndex - 5) / 5
    }

    private func boardColumn(for gridIndex: Int) -> Int {
        (gridIndex - 5) % 5
    }
}

#Preview {
    MiniCactpotBoardView(
        cells: [nil, nil, 6, nil, 7, nil, 9, nil, 3],
        highlightedLineID: 4
    ) { _ in }
    .padding()
}
