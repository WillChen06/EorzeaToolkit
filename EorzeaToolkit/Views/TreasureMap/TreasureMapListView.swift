import SwiftUI
import ComposableArchitecture

struct TreasureMapListView: View {
    var onReturnHome: () -> Void
    @State private var store: StoreOf<TreasureMapFeature>
    
    init(
        store: StoreOf<TreasureMapFeature> = Store(initialState: TreasureMapFeature.State()) {
            TreasureMapFeature()
        },
        onReturnHome: @escaping () -> Void = {}
    ) {
        _store = State(initialValue: store)
        self.onReturnHome = onReturnHome
    }

    var body: some View {
        FeatureNavigationView(
            feature: .treasureMap,
            selectionID: store.selectedMapID,
            onReturnHome: onReturnHome,
            hidesSidebarTitleWhenSplit: true
        ) {
            sidebar
        } detail: {
            if let map = store.selectedMap {
                TreasureMapDetailView(map: map)
            }
        }
        .task {
            store.send(.task)
        }
    }

    private var sidebar: some View {
        Group {
            switch store.loadState {
            case .idle, .loading:
                ProgressView(L10n.TreasureMap.loading)
            case let .failed(loadError):
                ContentUnavailableView(
                    L10n.TreasureMap.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            case let .loaded(catalog):
                loadedContent(catalog: catalog, maps: store.displayedMaps)
            }
        }
        .navigationTitle(L10n.TreasureMap.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortButton
            }

            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
        }
        .sheet(item: $store.scope(state: \.gathering, action: \.gathering)) { gatheringStore in
            GatheringNodesSheetView(store: gatheringStore)
                .presentationDetents([.medium, .large])
        }
        .appThemedBackground()
        .appThemedScreen(tint: HomeFeature.treasureMap.accent)
    }

    @ViewBuilder
    private func loadedContent(catalog: TreasureMapCatalog, maps: [TreasureMap]) -> some View {
        if catalog.maps.isEmpty {
            ContentUnavailableView(
                L10n.TreasureMap.emptyTitle,
                systemImage: "map",
                description: Text(L10n.TreasureMap.emptyDescription)
            )
        } else if maps.isEmpty && store.isFilterActive {
            ContentUnavailableView {
                Label(L10n.TreasureMap.filteredEmptyTitle, systemImage: "line.3.horizontal.decrease.circle")
            } actions: {
                Button(L10n.TreasureMap.clearFilters) {
                    store.send(.clearFiltersButtonTapped)
                }
            }
        } else {
            List(maps, selection: $store.selectedMapID.sending(\.mapSelected)) { map in
                NavigationLink(value: map.id) {
                    TreasureMapRow(map: map) {
                        store.send(.gatheringButtonTapped(map.id))
                    }
                }
                .appThemedListRow()
                .accessibilityIdentifier("treasureMap.row.\(map.id)")
            }
            .listStyle(.insetGrouped)
            .appThemedScrollContent()
        }
    }

    private var sortButton: some View {
        Button(
            store.sortDirection == .ascending
                ? L10n.TreasureMap.sortAscending
                : L10n.TreasureMap.sortDescending,
            systemImage: store.sortDirection == .ascending ? "arrow.up" : "arrow.down"
        ) {
            store.send(.sortButtonTapped)
        }
    }

    private var filterButton: some View {
        Button {
            store.send(.filterPresentationChanged(true))
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .frame(width: 36, height: 36)

                if store.activeFilterCount > 0 {
                    Text(store.activeFilterCount, format: .number)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(.red, in: Circle())
                        .padding(.top, 1)
                        .padding(.trailing, 1)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel(Text(L10n.TreasureMap.filterAction))
        .accessibilityIdentifier("treasureMap.filter.open")
        .accessibilityValue(Text(L10n.TreasureMap.filterSelectionCount(store.activeFilterCount)))
        .adaptivePopover(isPresented: $store.isFilterPresented.sending(\.filterPresentationChanged)) {
            TreasureMapFilterSheet(store: store)
                .frame(idealWidth: 440, idealHeight: 600)
        }
    }
}

private struct TreasureMapRow: View {
    let map: TreasureMap
    let showGatheringNodes: () -> Void

    private var accent: Color {
        map.type == .party ? .orange : .blue
    }

    private var hasGatheringNodes: Bool {
        !map.gatheringTypes.isEmpty && !map.gatheringZoneIds.isEmpty
    }

    var body: some View {
        HStack(spacing: 14) {
            gradeBadge

            VStack(alignment: .leading, spacing: 7) {
                Text(map.name)
                    .font(.headline)
                    .lineLimit(2)

                metadataRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
    }

    private var gradeBadge: some View {
        VStack(spacing: 2) {
            Text(map.grade)
                .accessibilityIdentifier("treasureMap.grade.\(map.id)")
                .font(.headline.weight(.bold))
                .foregroundStyle(accent)

            Text(L10n.TreasureMap.level(map.level))
                .font(.caption.bold())
                .foregroundStyle(AppTheme.mutedInk)
        }
        .frame(width: 56, height: 56)
        .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(accent.opacity(0.28), lineWidth: 1)
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 7) {
            metadataBadge(map.type.label, accent: accent)
            metadataText(L10n.TreasureMap.expansion(map.expansion))

            if hasGatheringNodes {
                Button(action: showGatheringNodes) {
                    HStack(spacing: 3) {
                        Image(systemName: "leaf")
                            .imageScale(.small)
                            .accessibilityHidden(true)
                        Text(L10n.TreasureMap.gatheringNodes)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .overlay {
                        Capsule()
                            .strokeBorder(.green.opacity(0.45), lineWidth: 1)
                    }
                    // Keep the capsule as small as the other badges but extend the tap area to about 44pt.
                    .contentShape(Rectangle().inset(by: -12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func metadataBadge(_ text: String, accent: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(accent.opacity(0.14), in: Capsule())
            .foregroundStyle(accent)
    }

    private func metadataText(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppTheme.mutedInk)
    }
}

#Preview {
    TreasureMapListView()
}
