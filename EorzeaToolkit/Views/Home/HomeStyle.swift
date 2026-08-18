import SwiftUI

enum AppTheme {
    static let pageBackground = LinearGradient(
        colors: [
            parchmentTop,
            parchmentBottom
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let bannerBackground = LinearGradient(
        colors: [
            parchmentLight,
            parchmentTop,
            parchmentBottom
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let heroArtworkBackground = LinearGradient(
        colors: [
            Color(.homeHeroArtworkTop),
            Color(.homeHeroArtworkBottom)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let placeholderBackground = LinearGradient(
        colors: [
            parchmentLight,
            parchmentTop
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let artworkBackground = LinearGradient(
        colors: [
            parchmentLight,
            Color(.homeArtworkBottom)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let surface = Color(.homeCardBackground)
    static let surfaceDepth = Color(.homeCardDepthBackground)
    static let parchmentLight = Color(.homeParchmentLight)
    static let parchmentTop = Color(.homeParchmentTop)
    static let parchmentBottom = Color(.homeParchmentBottom)
    static let ink = Color(.homeInk)
    static let mutedInk = Color(.homeMutedInk)
    static let gold = Color(.brandGold)
    static let crystal = Color(.brandCrystal)
    static let aetherBlue = Color(.brandAetherBlue)
    static let crimson = Color(.brandCrimson)
    static let shadow = Color(.homeShadow)
}

extension View {
    func appThemedScreen(tint: Color) -> some View {
        foregroundStyle(AppTheme.ink)
            .tint(tint)
            .toolbarBackground(AppTheme.parchmentTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }

    func appThemedBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.pageBackground.ignoresSafeArea())
    }

    func appThemedScrollContent() -> some View {
        scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground.ignoresSafeArea())
    }

    func appThemedListRow() -> some View {
        listRowBackground(AppTheme.surface)
            .listRowSeparatorTint(AppTheme.gold.opacity(0.22))
    }

    func appThemedCard(cornerRadius: CGFloat = 10) -> some View {
        background(AppTheme.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppTheme.gold.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: AppTheme.shadow.opacity(0.45), radius: 6, y: 3)
    }
}
