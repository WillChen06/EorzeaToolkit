import SwiftUI

struct TreasureMapDetailView: View {
    let map: TreasureMap
    private var zones: [TreasureZone] {
        map.zones
    }

    var body: some View {
        List {
            Section(L10n.TreasureMap.selectMap(count: zones.count)) {
                ForEach(zones) { zone in
                    NavigationLink {
                        TreasureSpotListView(zone: zone, partySize: map.maxPartySize)
                    } label: {
                        HStack {
                            Text(zone.name)
                            Spacer()
                            Text(L10n.TreasureMap.spotCount(zone.spots.count))
                                .font(.caption)
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                    }
                }
            }
            .appThemedListRow()
        }
        .appThemedScrollContent()
        .accessibilityIdentifier("treasureMap.detail.\(map.id)")
        .navigationTitle(map.grade)
        .navigationBarTitleDisplayMode(.inline)
        .appThemedScreen(tint: HomeFeature.treasureMap.accent)
    }
}
