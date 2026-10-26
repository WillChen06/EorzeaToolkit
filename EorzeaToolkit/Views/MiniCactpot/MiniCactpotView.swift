import SwiftUI

struct MiniCactpotView: View {
    var onReturnHome: () -> Void = {}
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
        NavigationStack {
            calculator
                .toolbar {
                    ReturnHomeToolbarItem(feature: .miniCactpot, action: onReturnHome)
                }
        }
    }

    private var calculator: some View {
        calculatorContent
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

    @ViewBuilder
    private var calculatorContent: some View {
        if horizontalSizeClass == .regular {
            // iPad and the unfolded iPhone Duo: the board on the left, results and payouts on the right.
            // Two Lists side by side lay out unreliably on the iPhone Duo (no margin on the edge in the
            // middle, content shifting after folding), so both columns are plain scroll views of cards
            // drawn like List sections, with the same margins on every side.
            HStack(alignment: .top, spacing: 0) {
                ScrollView {
                    boardCard
                        .padding(.leading, MiniCactpotCardMetrics.columnMargin)
                        .padding(.trailing, MiniCactpotCardMetrics.columnMargin / 2)
                        .padding(.vertical, MiniCactpotCardMetrics.columnMargin)
                }

                ScrollView {
                    VStack(spacing: MiniCactpotCardMetrics.columnMargin) {
                        MiniCactpotResultCards(results: results)

                        MiniCactpotPayoutTableView()
                            .miniCactpotCardRow()
                            .miniCactpotCard()
                    }
                    .padding(.leading, MiniCactpotCardMetrics.columnMargin / 2)
                    .padding(.trailing, MiniCactpotCardMetrics.columnMargin)
                    .padding(.vertical, MiniCactpotCardMetrics.columnMargin)
                }
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
        } else {
            List {
                boardSection
                MiniCactpotResultView(results: results)
                payoutSection
            }
            .appThemedScrollContent()
        }
    }

    private var boardSection: some View {
        Section {
            board
            progressLabel
        }
        .appThemedListRow()
    }

    private var boardCard: some View {
        VStack(spacing: 0) {
            board
                .miniCactpotCardRow()

            MiniCactpotCardSeparator()

            progressLabel
                .miniCactpotCardRow()
        }
        .miniCactpotCard()
    }

    private var board: some View {
        MiniCactpotBoardView(
            cells: cells,
            highlightedLineID: highlightedLineID
        ) { index in
            selectedCellIndex = index
        }
    }

    private var progressLabel: some View {
        Text(progressText)
            .font(.subheadline)
            .foregroundStyle(AppTheme.mutedInk)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var payoutSection: some View {
        Section {
            MiniCactpotPayoutTableView()
        }
        .appThemedListRow()
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

/// Cards for the wide layout, drawn to match the sections of the List the compact layout uses.
enum MiniCactpotCardMetrics {
    static let columnMargin: CGFloat = 20
    static let rowHorizontalPadding: CGFloat = 20
    static let rowVerticalPadding: CGFloat = 11
    static let cornerRadius: CGFloat = 26
}

struct MiniCactpotCardSeparator: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(AppTheme.gold.opacity(0.22))
            .frame(height: 1 / displayScale)
            .padding(.leading, MiniCactpotCardMetrics.rowHorizontalPadding)
    }
}

extension View {
    func miniCactpotCardRow() -> some View {
        padding(.horizontal, MiniCactpotCardMetrics.rowHorizontalPadding)
            .padding(.vertical, MiniCactpotCardMetrics.rowVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func miniCactpotCard() -> some View {
        background(
            AppTheme.surface,
            in: RoundedRectangle(cornerRadius: MiniCactpotCardMetrics.cornerRadius, style: .continuous)
        )
    }
}

#Preview {
    MiniCactpotView()
}
