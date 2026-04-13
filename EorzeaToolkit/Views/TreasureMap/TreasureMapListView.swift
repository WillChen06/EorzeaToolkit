import SwiftUI

struct TreasureMapListView: View {
    @State private var viewModel = TreasureMapViewModel()
    @State private var selectedMapForGathering: TreasureMap?

    var body: some View {
        List(viewModel.maps) { map in
            NavigationLink(destination: TreasureMapDetailView(map: map, zones: viewModel.zones(for: map), viewModel: viewModel)) {
                HStack(spacing: 12) {
                    Text(map.grade)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(map.type == .party ? .orange : .blue)
                        .frame(width: 40, alignment: .center)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(map.name)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text(map.type.label)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(map.type == .party ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15))
                                .foregroundStyle(map.type == .party ? .orange : .blue)
                                .clipShape(Capsule())
                            Text("v\(map.expansion)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Lv.\(map.level)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if !map.gatheringTypes.isEmpty && !map.gatheringZoneIds.isEmpty {
                                Button {
                                    selectedMapForGathering = map
                                } label: {
                                    HStack(spacing: 2) {
                                        Text("採集點")
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .foregroundStyle(.green)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(.green.opacity(0.5), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("藏寶圖")
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

#Preview {
    NavigationStack {
        TreasureMapListView()
    }
}
