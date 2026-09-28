import SwiftUI

struct FeatureNavigationView<Selection: Hashable, Sidebar: View, Detail: View>: View {
    let feature: HomeFeature
    let selectionID: Selection?
    let onReturnHome: () -> Void
    @ViewBuilder let sidebar: () -> Sidebar
    @ViewBuilder let detail: () -> Detail

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar()
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(L10n.Navigation.home, systemImage: "house", action: onReturnHome)
                    }
                }
        } detail: {
            NavigationStack {
                if selectionID != nil {
                    detail()
                } else {
                    ContentUnavailableView(
                        feature.title,
                        systemImage: feature.systemImage,
                        description: Text(L10n.Navigation.selectItem)
                    )
                    .appThemedBackground()
                }
            }
            // Changing the selection resets only its detail, never the feature's search/filter state.
            .id(selectionID)
        }
        .navigationSplitViewStyle(.balanced)
        .appThemedScreen(tint: feature.accent)
    }
}
