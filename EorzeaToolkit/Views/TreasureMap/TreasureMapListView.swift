import SwiftUI

struct TreasureMapListView: View {
    @State private var viewModel = TreasureMapViewModel()
    @State private var selectedMapForGathering: TreasureMap?
    @State private var isShowingFilterSheet = false
    @State private var hasInitializedPresentationState = false

    var body: some View {
        Group {
            if let loadError = viewModel.loadError {
                ContentUnavailableView(
                    L10n.TreasureMap.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if !viewModel.hasLoadedMaps {
                ProgressView(L10n.TreasureMap.loading)
            } else if viewModel.maps.isEmpty {
                ContentUnavailableView(
                    L10n.TreasureMap.emptyTitle,
                    systemImage: "map",
                    description: Text(L10n.TreasureMap.emptyDescription)
                )
            } else if viewModel.displayedMaps.isEmpty && viewModel.isFilterActive {
                ContentUnavailableView {
                    Label(L10n.TreasureMap.filteredEmptyTitle, systemImage: "line.3.horizontal.decrease.circle")
                } actions: {
                    Button(L10n.TreasureMap.clearFilters, action: viewModel.clearFilters)
                }
            } else {
                List(viewModel.displayedMaps) { map in
                    NavigationLink(destination: TreasureMapDetailView(map: map, zones: viewModel.zones(for: map), viewModel: viewModel)) {
                        TreasureMapRow(map: map) {
                            selectedMapForGathering = map
                        }
                    }
                    .appThemedListRow()
                }
                .listStyle(.insetGrouped)
                .appThemedScrollContent()
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
        .onAppear {
            guard !hasInitializedPresentationState else {
                return
            }

            viewModel.resetPresentationState()
            hasInitializedPresentationState = true
        }
        .task {
            viewModel.loadMaps()
        }
        .sheet(isPresented: $isShowingFilterSheet) {
            TreasureMapFilterSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedMapForGathering) { map in
            GatheringNodesSheetView(
                map: map,
                nodes: viewModel.gatheringNodes(for: map),
                viewModel: viewModel
            )
            .presentationDetents([.medium, .large])
        }
        .appThemedBackground()
        .appThemedScreen(tint: HomeFeature.treasureMap.accent)
    }

    private var sortButton: some View {
        Button(
            viewModel.sortDirection == .ascending
                ? L10n.TreasureMap.sortAscending
                : L10n.TreasureMap.sortDescending,
            systemImage: viewModel.sortDirection == .ascending ? "arrow.up" : "arrow.down",
            action: viewModel.toggleSortDirection
        )
    }

    private var filterButton: some View {
        Button {
            isShowingFilterSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .frame(width: 36, height: 36)

                if viewModel.activeFilterCount > 0 {
                    Text(viewModel.activeFilterCount, format: .number)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(.red, in: Circle())
                        .padding(.top, 1)
                        .padding(.trailing, 1)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: 44, height: 44)
        }
        .accessibilityLabel(Text(L10n.TreasureMap.filterAction))
        .accessibilityValue(Text(L10n.TreasureMap.filterSelectionCount(viewModel.activeFilterCount)))
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
                    Label {
                        Text(L10n.TreasureMap.gatheringNodes)
                    } icon: {
                        Image(systemName: "leaf")
                    }
                        .font(.caption.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 7)
                        .foregroundStyle(.green)
                        .frame(minHeight: 44)
                        .overlay {
                            Capsule()
                                .strokeBorder(.green.opacity(0.45), lineWidth: 1)
                        }
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
    NavigationStack {
        TreasureMapListView()
    }
}
