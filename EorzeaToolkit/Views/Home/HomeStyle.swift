import SwiftUI

enum HomeStyle {
    static let background = LinearGradient(
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
    static let cardBackground = Color(.homeCardBackground)
    static let cardDepthBackground = Color(.homeCardDepthBackground)
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
