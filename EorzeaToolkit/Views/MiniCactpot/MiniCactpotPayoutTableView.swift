import SwiftUI

struct MiniCactpotPayoutTableView: View {
    private let payoutRows = MiniCactpotCalculator.payout.keys.sorted()

    var body: some View {
        DisclosureGroup("獎勵表") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(payoutRows, id: \.self) { sum in
                    Text("\(sum)")
                        .font(.body.monospacedDigit())
                    Text("\(MiniCactpotCalculator.payout[sum] ?? 0)")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.fixed(44), alignment: .leading),
            GridItem(.flexible(), alignment: .trailing)
        ]
    }
}

#Preview {
    List {
        MiniCactpotPayoutTableView()
    }
}
