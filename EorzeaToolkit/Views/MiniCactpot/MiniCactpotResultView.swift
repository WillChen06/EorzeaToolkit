import SwiftUI

struct MiniCactpotResultView: View {
    let results: [MiniCactpotResult]

    var body: some View {
        if let bestResult = results.first {
            Section {
                MiniCactpotRecommendationView(result: bestResult)
                    .padding(.vertical, 4)
            }
            .appThemedListRow()

            Section(L10n.MiniCactpot.Result.allLines) {
                ForEach(results) { result in
                    MiniCactpotLineResultRow(result: result, isBest: result.id == bestResult.id)
                }
            }
            .appThemedListRow()
        }
    }
}

/// The results as standalone cards, for the wide layout where the calculator is not a List.
struct MiniCactpotResultCards: View {
    let results: [MiniCactpotResult]

    var body: some View {
        if let bestResult = results.first {
            MiniCactpotRecommendationView(result: bestResult)
                .padding(.vertical, 4)
                .miniCactpotCardRow()
                .miniCactpotCard()

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.MiniCactpot.Result.allLines)
                    .font(.headline)
                    .padding(.horizontal, MiniCactpotCardMetrics.rowHorizontalPadding)

                VStack(spacing: 0) {
                    ForEach(results) { result in
                        if result.id != bestResult.id {
                            MiniCactpotCardSeparator()
                        }

                        MiniCactpotLineResultRow(result: result, isBest: result.id == bestResult.id)
                            .miniCactpotCardRow()
                    }
                }
                .miniCactpotCard()
            }
        }
    }
}

private struct MiniCactpotRecommendationView: View {
    let result: MiniCactpotResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.MiniCactpot.Result.recommendation(lineName: L10n.MiniCactpot.lineNameText(result.line)))
                .font(.headline)

            Text(L10n.MiniCactpot.Result.expectedValue(MiniCactpotResultFormat.expectedValueText(result.expectedValue)))
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MiniCactpotLineResultRow: View {
    let result: MiniCactpotResult
    let isBest: Bool

    var body: some View {
        HStack {
            Text(L10n.MiniCactpot.lineName(result.line))

            Spacer()

            Text(MiniCactpotResultFormat.expectedValueText(result.expectedValue))
                .font(.body.monospacedDigit())
                .foregroundStyle(isBest ? Color.orange : AppTheme.mutedInk)
        }
        .accessibilityElement(children: .combine)
    }
}

private enum MiniCactpotResultFormat {
    static func expectedValueText(_ expectedValue: Double) -> String {
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
