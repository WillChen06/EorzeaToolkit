import SwiftUI

struct TreasureMapListView: View {
    @State private var viewModel = TreasureMapViewModel()
    @State private var selectedMapForGathering: TreasureMap?

    var body: some View {
        Group {
            if let loadError = viewModel.loadError {
                ContentUnavailableView(
                    L10n.TreasureMap.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if !viewModel.maps.isEmpty {
                List(viewModel.maps) { map in
                    NavigationLink(destination: TreasureMapDetailView(map: map, zones: viewModel.zones(for: map), viewModel: viewModel)) {
                        TreasureMapRow(map: map) {
                            selectedMapForGathering = map
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else if viewModel.hasLoadedMaps {
                ContentUnavailableView(
                    L10n.TreasureMap.emptyTitle,
                    systemImage: "map",
                    description: Text(L10n.TreasureMap.emptyDescription)
                )
            } else {
                ProgressView(L10n.TreasureMap.loading)
            }
        }
        .navigationTitle(L10n.TreasureMap.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadMaps()
        }
        .sheet(item: $selectedMapForGathering) { map in
            GatheringNodesSheetView(
                map: map,
                nodes: viewModel.gatheringNodes(for: map),
                viewModel: viewModel
            )
            .presentationDetents([.medium, .large])
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
                .font(.headline.weight(.bold))
                .foregroundStyle(accent)

            Text(L10n.TreasureMap.level(map.level))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
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
                        .padding(.vertical, 3)
                        .foregroundStyle(.green)
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
            .foregroundStyle(.secondary)
    }
}

#Preview {
    NavigationStack {
        TreasureMapListView()
    }
}
