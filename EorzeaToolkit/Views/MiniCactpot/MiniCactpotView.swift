import SwiftUI

struct MiniCactpotView: View {
    @State private var cells: [Int?] = Array(repeating: nil, count: 9)
    @State private var selectedCellIndex: Int?

    private var openedCount: Int {
        cells.compactMap { $0 }.count
    }

    private var usedNumbers: Set<Int> {
        Set(cells.compactMap { $0 })
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
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            MiniCactpotResultView(results: results)

            Section {
                MiniCactpotPayoutTableView()
            }

            Section {
                Button("重置", role: .destructive) {
                    cells = Array(repeating: nil, count: 9)
                }
            }
        }
        .navigationTitle("仙人微彩")
        .confirmationDialog(
            "選擇數字",
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
                    Button("清除", role: .destructive) {
                        cells[selectedCellIndex] = nil
                    }
                }
            }
        }
    }

    private var progressText: String {
        if openedCount < 4 {
            return "已開 \(openedCount)/4 格 · 再開 \(4 - openedCount) 格"
        }

        return "已開 \(openedCount) 格 · 已可計算"
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
}

#Preview {
    NavigationStack {
        MiniCactpotView()
    }
}
