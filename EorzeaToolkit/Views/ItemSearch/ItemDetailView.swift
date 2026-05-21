import SwiftUI

struct ItemDetailView: View {
    let item: Item

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    ItemIconView(item: item, size: 96)

                    VStack(spacing: 6) {
                        Text(item.displayName)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text("iLv \(item.ilvl)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            MarketPriceSection(item: item)

            Section("後續擴充") {
                Label("取得方式、配方與採集將在後續 Phase 補上", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
