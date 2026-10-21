import SwiftUI

/// The Home button at the leading edge of every feature's top bar.
struct ReturnHomeToolbarItem: ToolbarContent {
    let feature: HomeFeature
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(L10n.Navigation.home, systemImage: "house", action: action)
                .accessibilityIdentifier("navigation.home.\(feature.id)")
        }
    }
}
