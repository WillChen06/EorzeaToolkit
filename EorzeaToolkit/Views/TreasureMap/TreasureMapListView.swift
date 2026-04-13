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
                                    Label("採集點", systemImage: "leaf")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundStyle(.green)
                                        .clipShape(Capsule())
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
                nodes: viewModel.gatheringNodes(for: map)
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
