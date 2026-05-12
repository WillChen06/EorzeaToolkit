import SwiftUI

struct TreasureMapDetailView: View {
    let map: TreasureMap
    let zones: [TreasureZone]
    let viewModel: TreasureMapViewModel

    var body: some View {
        List {
            Section("選擇地圖（\(zones.count)）") {
                ForEach(zones) { zone in
                    NavigationLink {
                        TreasureSpotListView(
                            zoneName: zone.name,
                            spots: viewModel.spots(for: map, in: zone),
                            mapImageURL: viewModel.mapImageURL(for: zone.mapId)
                        )
                    } label: {
                        HStack {
                            Text(zone.name)
                            Spacer()
                            Text("\(zone.spotCount) 個點位")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(map.grade)
        .navigationBarTitleDisplayMode(.inline)
    }
}
