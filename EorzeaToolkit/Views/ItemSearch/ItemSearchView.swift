import SwiftUI

struct ItemSearchView: View {
    var onReturnHome: () -> Void = {}
    @State private var viewModel = ItemSearchViewModel(descriptionSearchEngine: .live)
    // Only item details show market prices. The settings restore the saved server, so
    // leaving for the home page and coming back keeps it.
    @State private var marketPriceSettings = MarketPriceSettings()
    @State private var selectedItemID: Int?
    @State private var isShowingFilterSheet = false

    var body: some View {
        FeatureNavigationView(
            feature: .itemSearch,
            selectionID: selectedItemID,
            onReturnHome: onReturnHome,
            hidesSidebarTitleWhenSplit: true
        ) {
            sidebar
        } detail: {
            if let selectedItemID, let item = viewModel.itemsByID[selectedItemID] {
                ItemDetailView(item: item, itemsByID: viewModel.itemsByID)
            }
        }
        .environment(marketPriceSettings)
        .task {
            viewModel.loadItems()
            viewModel.refreshDescriptionSearchAvailability()
        }
        .onChange(of: viewModel.itemIDToOpen) { _, itemID in
            // A recipe lookup found exactly one item with that name.
            guard let itemID else {
                return
            }
            selectedItemID = itemID
            viewModel.didOpenItem()
        }
    }

    private var sidebar: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView(L10n.ItemSearch.loadingItems)
            case .loaded:
                loadedContent
            case .failed(let message):
                ContentUnavailableView(
                    L10n.ItemSearch.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle(L10n.ItemSearch.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateSearchQuery($0) }
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: L10n.ItemSearch.searchPrompt
        )
        .toolbar {
            // One group, so the system places both buttons together.
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.showsDescriptionSearchButton {
                    descriptionSearchButton
                }

                filterButton
            }
        }
        .appThemedBackground()
        .appThemedScreen(tint: HomeFeature.itemSearch.accent)
    }

    private var descriptionSearchButton: some View {
        Button {
            viewModel.openDescriptionSearch()
        } label: {
            Image(systemName: "sparkles")
                .font(.title3)
                .frame(width: 36, height: 36)
        }
        .disabled(!viewModel.canOpenDescriptionSearch)
        .accessibilityLabel(Text(L10n.ItemSearch.DescriptionSearch.title))
        .popover(isPresented: isShowingDescriptionSearch) {
            ItemDescriptionSearchSheet(viewModel: viewModel)
                .frame(idealWidth: 440, idealHeight: 360)
                .presentationCompactAdaptation(horizontal: .sheet, vertical: .sheet)
        }
    }

    /// Dismissing the screen, by swiping it down or tapping outside the popover, closes it as
    /// 「取消」 does, abandoning a parse in progress.
    private var isShowingDescriptionSearch: Binding<Bool> {
        Binding(
            get: { viewModel.isShowingDescriptionSearch },
            set: { isShowing in
                if !isShowing {
                    viewModel.closeDescriptionSearch()
                }
            }
        )
    }

    private var filterButton: some View {
        Button {
            isShowingFilterSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .frame(width: 36, height: 36)

                // Always there and only hidden while the filter is at its defaults: inserting the
                // badge changed the button's structure, and with a second button beside it,
                // iPhone Duo then moved this button to the bottom of the screen and stretched the
                // buttons' shared glass background between them.
                Text("\(viewModel.filter.activeFilterCount)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(.red, in: Circle())
                    .padding(.top, 1)
                    .padding(.trailing, 1)
                    .opacity(viewModel.filter.isActive ? 1 : 0)
                    .accessibilityHidden(!viewModel.filter.isActive)
            }
        }
        .accessibilityLabel(Text(L10n.ItemSearch.filterAccessibility))
        // Both entry points use this stable anchor, even when clearing removes the summary bar.
        .popover(isPresented: $isShowingFilterSheet) {
            ItemFilterSheet(viewModel: viewModel)
                .frame(idealWidth: 440, idealHeight: 600)
                .presentationCompactAdaptation(horizontal: .sheet, vertical: .sheet)
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 0) {
            if shouldShowFilterBar {
                filterBar
            }

            searchContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var shouldShowFilterBar: Bool {
        !viewModel.isWaitingForSearch || viewModel.isSearching
    }

    private var filterBar: some View {
        Button {
            isShowingFilterSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .imageScale(.small)

                if viewModel.filter.isActive {
                    Text(activeFilterBarText)
                        .lineLimit(1)
                } else {
                    Text(L10n.ItemSearch.adjustFilter)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(L10n.ItemSearch.filterAction)
                    .fontWeight(.semibold)
            }
            .font(.footnote)
            .foregroundStyle(AppTheme.mutedInk)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(AppTheme.surface)
        .overlay(alignment: .bottom) {
            AppTheme.gold.opacity(0.22)
                .frame(height: 1)
        }
    }

    private var activeFilterBarText: String {
        viewModel.filterSummaryParts.joined(separator: " · ")
    }

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.isWaitingForSearch {
            ContentUnavailableView(
                L10n.ItemSearch.emptySearchTitle,
                systemImage: "magnifyingglass",
                description: Text(L10n.ItemSearch.emptySearchDescription)
            )
        } else if viewModel.results.isEmpty {
            if viewModel.isSearching {
                ProgressView(L10n.ItemSearch.searching)
            } else {
                ContentUnavailableView(
                    L10n.ItemSearch.noResultsTitle,
                    systemImage: "shippingbox",
                    description: Text(
                        viewModel.isFilterOnlySearch
                            ? L10n.ItemSearch.noFilterResultsDescription
                            : L10n.ItemSearch.noResultsDescription
                    )
                )
            }
        } else {
            List(selection: $selectedItemID) {
                ForEach(viewModel.results) { item in
                    NavigationLink(value: item.id) {
                        ItemSearchRow(item: item)
                    }
                    .appThemedListRow()
                }

                if viewModel.hiddenResultCount > 0 {
                    Button {
                        viewModel.loadMoreResults()
                    } label: {
                        VStack(spacing: 4) {
                            Text(L10n.ItemSearch.loadMore)
                                .font(.subheadline.weight(.semibold))

                            Text(L10n.ItemSearch.resultsStatus(
                                visibleCount: viewModel.results.count,
                                totalCount: viewModel.totalMatchCount,
                                hiddenCount: viewModel.hiddenResultCount
                            ))
                                .font(.footnote)
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .appThemedListRow()
                }
            }
            .appThemedScrollContent()
            .overlay(alignment: .topTrailing) {
                if viewModel.isSearching {
                    ProgressView()
                        .controlSize(.small)
                        .padding()
                }
            }
        }
    }
}

private struct ItemSearchRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            ItemIconView(item: item, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)

                Text(L10n.ItemSearch.levelText(for: item))
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ItemSearchView()
}
