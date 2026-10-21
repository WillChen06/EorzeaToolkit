import SwiftUI

struct FeatureNavigationView<Selection: Hashable, Sidebar: View, Detail: View>: View {
    let feature: HomeFeature
    let selectionID: Selection?
    let onReturnHome: () -> Void
    /// For a sidebar whose toolbar buttons leave its title no room beside the home button and
    /// the sidebar toggle. The title only goes while both columns show; it comes back once the
    /// view collapses into one.
    var hidesSidebarTitleWhenSplit = false
    @ViewBuilder let sidebar: () -> Sidebar
    @ViewBuilder let detail: () -> Detail

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar()
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
                .toolbar {
                    ReturnHomeToolbarItem(feature: feature, action: onReturnHome)
                }
                .toolbar(removing: removedSidebarItem)
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

    /// Read here rather than inside the sidebar, which can report its own column's size class.
    private var removedSidebarItem: ToolbarDefaultItemKind? {
        hidesSidebarTitleWhenSplit && horizontalSizeClass == .regular ? .title : nil
    }
}
