import SwiftUI

struct MiniCactpotBoardView: View {
    let cells: [Int?]
    let highlightedLineID: Int?
    let cellAction: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                MiniCactpotArrowView(line: MiniCactpotLine.all[6], isHighlighted: highlightedLineID == 6)

                ForEach(MiniCactpotLine.all[3...5]) { line in
                    MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                }

                MiniCactpotArrowView(line: MiniCactpotLine.all[7], isHighlighted: highlightedLineID == 7)
            }

            HStack(spacing: 10) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cells.indices, id: \.self) { index in
                        MiniCactpotCellView(value: cells[index]) {
                            cellAction(index)
                        }
                    }
                }
                .frame(maxWidth: 260)

                VStack(spacing: 10) {
                    ForEach(MiniCactpotLine.all[0...2]) { line in
                        MiniCactpotArrowView(line: line, isHighlighted: highlightedLineID == line.id)
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

#Preview {
    MiniCactpotBoardView(
        cells: [nil, nil, 6, nil, 7, nil, 9, nil, 3],
        highlightedLineID: 4
    ) { _ in }
    .padding()
}
