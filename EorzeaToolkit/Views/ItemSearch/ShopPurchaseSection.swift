import SwiftUI

struct ShopPurchaseSection: View {
    let entry: ItemShopEntry

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label(ObtainSource.shop.title, systemImage: ObtainSource.shop.systemImage)
                    .font(.headline)

                Text(priceText)
                    .font(.title3.weight(.semibold).monospacedDigit())

                Text(L10n.ShopPurchase.sourceNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var priceText: String {
        guard let priceMid = entry.priceMid else {
            return L10n.Common.notProvidedText
        }

        return L10n.ShopPurchase.priceText(priceMid.formatted())
    }
}
