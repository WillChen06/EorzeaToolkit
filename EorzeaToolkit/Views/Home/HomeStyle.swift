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
            dynamicColor(
                light: UIColor(red: 0.84, green: 0.88, blue: 0.84, alpha: 1),
                dark: UIColor(red: 0.20, green: 0.24, blue: 0.25, alpha: 1)
            ),
            dynamicColor(
                light: UIColor(red: 0.72, green: 0.66, blue: 0.48, alpha: 1),
                dark: UIColor(red: 0.14, green: 0.13, blue: 0.10, alpha: 1)
            )
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
            dynamicColor(
                light: UIColor(red: 0.93, green: 0.87, blue: 0.72, alpha: 1),
                dark: UIColor(red: 0.22, green: 0.18, blue: 0.13, alpha: 1)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackground = dynamicColor(
        light: UIColor(red: 0.99, green: 0.96, blue: 0.88, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.20, blue: 0.15, alpha: 1)
    )
    static let cardDepthBackground = dynamicColor(
        light: UIColor(red: 0.95, green: 0.90, blue: 0.78, alpha: 1),
        dark: UIColor(red: 0.29, green: 0.24, blue: 0.17, alpha: 1)
    )
    static let parchmentLight = dynamicColor(
        light: UIColor(red: 0.99, green: 0.96, blue: 0.86, alpha: 1),
        dark: UIColor(red: 0.30, green: 0.25, blue: 0.18, alpha: 1)
    )
    static let parchmentTop = dynamicColor(
        light: UIColor(red: 0.96, green: 0.92, blue: 0.82, alpha: 1),
        dark: UIColor(red: 0.18, green: 0.16, blue: 0.13, alpha: 1)
    )
    static let parchmentBottom = dynamicColor(
        light: UIColor(red: 0.88, green: 0.80, blue: 0.64, alpha: 1),
        dark: UIColor(red: 0.12, green: 0.11, blue: 0.09, alpha: 1)
    )
    static let ink = dynamicColor(
        light: UIColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 1),
        dark: UIColor(red: 0.93, green: 0.87, blue: 0.74, alpha: 1)
    )
    static let mutedInk = dynamicColor(
        light: UIColor(red: 0.42, green: 0.34, blue: 0.23, alpha: 1),
        dark: UIColor(red: 0.76, green: 0.68, blue: 0.54, alpha: 1)
    )
    static let gold = dynamicColor(
        light: UIColor(red: 0.62, green: 0.47, blue: 0.22, alpha: 1),
        dark: UIColor(red: 0.78, green: 0.62, blue: 0.34, alpha: 1)
    )
    static let crystal = dynamicColor(
        light: UIColor(red: 0.20, green: 0.55, blue: 0.68, alpha: 1),
        dark: UIColor(red: 0.42, green: 0.78, blue: 0.88, alpha: 1)
    )
    static let aetherBlue = dynamicColor(
        light: UIColor(red: 0.26, green: 0.36, blue: 0.64, alpha: 1),
        dark: UIColor(red: 0.48, green: 0.58, blue: 0.88, alpha: 1)
    )
    static let crimson = dynamicColor(
        light: UIColor(red: 0.58, green: 0.22, blue: 0.18, alpha: 1),
        dark: UIColor(red: 0.86, green: 0.42, blue: 0.36, alpha: 1)
    )
    static let shadow = dynamicColor(
        light: UIColor(red: 0.20, green: 0.14, blue: 0.06, alpha: 0.18),
        dark: UIColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 0.32)
    )

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}
