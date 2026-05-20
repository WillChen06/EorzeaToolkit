import SwiftUI

struct ItemIconView: View {
    let item: Item
    let size: CGFloat

    var body: some View {
        CachedIconImage(url: item.iconURL) {
            placeholder
        }
        .padding(size * 0.08)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.12))

            Image(systemName: "shippingbox.fill")
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(.blue)
        }
    }
}
