import SwiftUI

struct ShopPurchaseSection: View {
    let entry: ItemShopEntry

    var body: some View {
        if entry.isShopPurchase {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("商店購買", systemImage: ObtainSource.shop.systemImage)
                        .font(.headline)

                    Text(priceText)
                        .font(.title3.weight(.semibold).monospacedDigit())

                    Text("售價來源:Item.PriceMid・NPC 與店家位置未提供")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var priceText: String {
        guard let priceMid = entry.priceMid else {
            return "未提供"
        }

        return "\(priceMid.formatted()) G"
    }
}
