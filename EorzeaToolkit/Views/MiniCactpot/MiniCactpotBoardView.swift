import SwiftUI

struct MiniCactpotBoardView: View {
    let cells: [Int?]
    let highlightedLineID: Int?
    let cellAction: (Int) -> Void

    private let arrowSize: CGFloat = 30
    private let boardWidth: CGFloat = 260
    private let spacing: CGFloat = 10

    private var cellSize: CGFloat {
        (boardWidth - spacing * 2) / 3
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 3)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                MiniCactpotArrowView(line: MiniCactpotLine.all[6], isHighlighted: highlightedLineID == 6)
                    .position(x: arrowSize / 2, y: arrowSize / 2)

                ForEach(MiniCactpotLine.all[3...5]) { line in
                    MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                        .position(x: columnCenter(for: line.id - 3), y: arrowSize / 2)
                }

                MiniCactpotArrowView(line: MiniCactpotLine.all[7], isHighlighted: highlightedLineID == 7)
                    .position(x: boardWidth - arrowSize / 2, y: arrowSize / 2)
            }
            .frame(width: boardWidth, height: arrowSize)

            HStack(alignment: .top, spacing: spacing) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cells.indices, id: \.self) { index in
                        MiniCactpotCellView(value: cells[index]) {
                            cellAction(index)
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                }
                .frame(width: boardWidth)

                VStack(spacing: spacing) {
                    ForEach(MiniCactpotLine.all[0...2]) { line in
                        MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                            .frame(width: arrowSize, height: cellSize)
                    }
                }
                .frame(width: arrowSize)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func columnCenter(for column: Int) -> CGFloat {
        cellSize / 2 + CGFloat(column) * (cellSize + spacing)
    }
}

#Preview {
    MiniCactpotBoardView(
        cells: [nil, nil, 6, nil, 7, nil, 9, nil, 3],
        highlightedLineID: 4
    ) { _ in }
    .padding()
}
