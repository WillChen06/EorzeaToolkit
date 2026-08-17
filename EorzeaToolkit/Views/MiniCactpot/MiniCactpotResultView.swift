import SwiftUI

struct MiniCactpotResultView: View {
    let results: [MiniCactpotResult]

    var body: some View {
        if let bestResult = results.first {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.MiniCactpot.Result.recommendation(lineName: L10n.MiniCactpot.lineNameText(bestResult.line)))
                        .font(.headline)

                    Text(L10n.MiniCactpot.Result.expectedValue(expectedValueText(bestResult.expectedValue)))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                }
                .padding(.vertical, 4)
            }
            .appThemedListRow()

            Section(L10n.MiniCactpot.Result.allLines) {
                ForEach(results) { result in
                    HStack {
                        Text(L10n.MiniCactpot.lineName(result.line))

                        Spacer()

                        Text(expectedValueText(result.expectedValue))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(result.id == bestResult.id ? Color.orange : AppTheme.mutedInk)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .appThemedListRow()
        }
    }

    private func expectedValueText(_ expectedValue: Double) -> String {
        expectedValue.formatted(.number.precision(.fractionLength(1)))
    }
}

#Preview {
    List {
        MiniCactpotResultView(
            results: MiniCactpotCalculator.calculateResults(
                cells: [nil, nil, 6, nil, 7, nil, 9, nil, 3]
            )
        )
    }
}
