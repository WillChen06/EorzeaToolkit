import SwiftUI

struct MiniCactpotView: View {
    @State private var cells: [Int?] = Array(repeating: nil, count: 9)
    @State private var selectedCellIndex: Int?

    private var openedCount: Int {
        cells.compactMap { $0 }.count
    }

    private var results: [MiniCactpotResult] {
        guard openedCount >= 4 else {
            return []
        }

        return MiniCactpotCalculator.calculateResults(cells: cells)
    }

    private var highlightedLineID: Int? {
        results.first?.line.id
    }

    var body: some View {
        List {
            Section {
                MiniCactpotBoardView(
                    cells: cells,
                    highlightedLineID: highlightedLineID
                ) { index in
                    selectedCellIndex = index
                }

                Text(progressText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .appThemedListRow()

            MiniCactpotResultView(results: results)

            Section {
                MiniCactpotPayoutTableView()
            }
            .appThemedListRow()
        }
        .appThemedScrollContent()
        .navigationTitle(L10n.MiniCactpot.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.Common.reset, role: .destructive, action: resetCells)
                    .disabled(openedCount == 0)
            }
        }
        .appThemedScreen(tint: HomeFeature.miniCactpot.accent)
        .confirmationDialog(
            L10n.MiniCactpot.selectNumber,
            isPresented: numberPickerBinding,
            titleVisibility: .visible
        ) {
            if let selectedCellIndex {
                ForEach(1...9, id: \.self) { number in
                    Button("\(number)") {
                        cells[selectedCellIndex] = number
                    }
                    .disabled(isNumberUsedByAnotherCell(number, selectedCellIndex: selectedCellIndex))
                }

                if cells[selectedCellIndex] != nil {
                    Button(L10n.Common.clear, role: .destructive) {
                        cells[selectedCellIndex] = nil
                    }
                }
            }
        }
    }

    private var progressText: LocalizedStringKey {
        if openedCount < 4 {
            return L10n.MiniCactpot.progressNeedMore(openedCount: openedCount, remainingCount: 4 - openedCount)
        }

        return L10n.MiniCactpot.progressReady(openedCount: openedCount)
    }

    private var numberPickerBinding: Binding<Bool> {
        Binding {
            selectedCellIndex != nil
        } set: { isPresented in
            if !isPresented {
                selectedCellIndex = nil
            }
        }
    }

    private func isNumberUsedByAnotherCell(_ number: Int, selectedCellIndex: Int) -> Bool {
        cells.enumerated().contains { index, value in
            index != selectedCellIndex && value == number
        }
    }

    private func resetCells() {
        cells = Array(repeating: nil, count: 9)
    }
}

#Preview {
    NavigationStack {
        MiniCactpotView()
    }
}
