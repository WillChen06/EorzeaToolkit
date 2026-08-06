import SwiftUI

struct HomeHeroBanner: View {
    var body: some View {
        heroArtwork
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(HomeStyle.gold.opacity(0.55), lineWidth: 1)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(HomeStyle.gold.opacity(0.24), lineWidth: 1)
                    .padding(6)
            }
        }
        .accessibilityLabel(Text(L10n.Home.heroAccessibilityLabel))
    }

    private var heroArtwork: some View {
        Image(.homeHeroBanner)
            .resizable()
            .scaledToFill()
            .clipped()
    }
}
