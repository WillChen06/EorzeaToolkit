import SwiftUI

struct MiniCactpotBoardView: View {
    let cells: [Int?]
    let highlightedLineID: Int?
    let cellAction: (Int) -> Void

    private let maxGridWidth: CGFloat = 340
    private let spacing: CGFloat = 10

    var body: some View {
        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            topArrowRow

            ForEach(0..<3, id: \.self) { row in
                boardRow(row)
            }
        }
        .frame(maxWidth: maxGridWidth)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var topArrowRow: some View {
        GridRow {
            ForEach(0..<5, id: \.self) { column in
                boardSlot {
                    if let line = topLine(for: column) {
                        MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                    }
                }
            }
        }
    }

    private func boardRow(_ row: Int) -> some View {
        GridRow {
            let line = MiniCactpotLine.all[row]
            boardSlot {
                MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
            }

            ForEach(0..<3, id: \.self) { column in
                let cellIndex = row * 3 + column
                boardSlot {
                    MiniCactpotCellView(value: cells[cellIndex]) {
                        cellAction(cellIndex)
                    }
                }
            }

            boardSlot {
                Color.clear
            }
        }
    }

    private func boardSlot<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
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
