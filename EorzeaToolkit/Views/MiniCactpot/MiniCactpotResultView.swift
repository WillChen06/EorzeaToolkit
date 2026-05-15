import SwiftUI

struct MiniCactpotResultView: View {
    let results: [MiniCactpotResult]

    var body: some View {
        if let bestResult = results.first {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("推薦：\(bestResult.line.name)")
                        .font(.headline)

                    Text("期望值 \(bestResult.expectedValue, format: .number.precision(.fractionLength(1))) 金碟幣")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("全部線路") {
                ForEach(results) { result in
                    HStack {
                        Text(result.line.name)

                        Spacer()

                        Text("\(result.expectedValue, format: .number.precision(.fractionLength(1)))")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(result.id == bestResult.id ? .orange : .secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
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
