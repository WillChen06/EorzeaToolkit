import SwiftUI

struct MiniCactpotPayoutTableView: View {
    private let payoutRows = MiniCactpotCalculator.payout.keys.sorted()

    var body: some View {
        DisclosureGroup("獎勵表") {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("和")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("獎勵（金碟幣）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        }
    }
}

#Preview {
    List {
        MiniCactpotPayoutTableView()
    }
}
