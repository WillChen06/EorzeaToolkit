import SwiftUI

struct MiniCactpotPayoutTableView: View {
    private let payoutRows = MiniCactpotCalculator.payout.keys.sorted()

    var body: some View {
        DisclosureGroup {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text(L10n.MiniCactpot.Payout.sum)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(L10n.MiniCactpot.Payout.reward)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                ForEach(payoutRows, id: \.self) { sum in
                    GridRow {
                        Text("\(sum)")
                            .font(.body.monospacedDigit())

                        Text("\(MiniCactpotCalculator.payout[sum] ?? 0)")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(.vertical, 6)
        } label: {
            Text(L10n.MiniCactpot.Payout.title)
        }
    }
}

#Preview {
    List {
        MiniCactpotPayoutTableView()
    }
}
