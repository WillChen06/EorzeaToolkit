import SwiftUI

struct TreasureMapDetailView: View {
    let map: TreasureMap
    let zones: [TreasureZone]
    let viewModel: TreasureMapViewModel

    var body: some View {
        List {
            Section(L10n.TreasureMap.selectMap(count: zones.count)) {
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
                            Text(L10n.TreasureMap.spotCount(zone.spotCount))
                                .font(.caption)
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                    }
                }
            }
            .appThemedListRow()
        }
        .appThemedScrollContent()
        .navigationTitle(map.grade)
        .navigationBarTitleDisplayMode(.inline)
        .appThemedScreen(tint: HomeFeature.treasureMap.accent)
    }
}
