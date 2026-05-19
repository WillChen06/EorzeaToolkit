import SwiftUI

struct TreasureMapListView: View {
    @State private var viewModel = TreasureMapViewModel()
    @State private var selectedMapForGathering: TreasureMap?

    var body: some View {
        Group {
            if !viewModel.maps.isEmpty {
                List(viewModel.maps) { map in
                    NavigationLink(destination: TreasureMapDetailView(map: map, zones: viewModel.zones(for: map), viewModel: viewModel)) {
                        TreasureMapRow(map: map) {
                            selectedMapForGathering = map
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else if let loadError = viewModel.loadError {
                FeatureStatusView("無法載入藏寶圖資料", systemImage: "exclamationmark.triangle", description: loadError)
            } else if viewModel.hasLoadedMaps {
                FeatureStatusView("尚無藏寶圖資料", systemImage: "map", description: "目前沒有可顯示的藏寶圖")
            } else {
                FeatureStatusView("載入藏寶圖資料", systemImage: "map", isLoading: true)
            }
        }
        .navigationTitle("藏寶圖")
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

            Text("Lv.\(map.level)")
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
            metadataText("v\(map.expansion)")

            if hasGatheringNodes {
                Button(action: showGatheringNodes) {
                    Label("採集點", systemImage: "leaf")
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

    private func metadataText(_ text: String) -> some View {
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
