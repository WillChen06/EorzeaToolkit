import SwiftUI

struct TreasureSpotListView: View {
    let zone: TreasureZone
    /// The map's maximum party size, shown on every card.
    let partySize: Int

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(zone.spots.enumerated()), id: \.element.id) { index, spot in
                    TreasureSpotCard(
                        index: index + 1,
                        spot: spot,
                        zone: zone,
                        partySize: partySize
                    )
                }
            }
            .padding()
        }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .appThemedBackground()
        .appThemedScreen(tint: HomeFeature.treasureMap.accent)
    }
}

// MARK: - 點位卡片

private struct TreasureSpotCard: View {
    let index: Int
    let spot: TreasureSpot
    let zone: TreasureZone
    let partySize: Int

    var body: some View {
        ZStack {
            // 藏寶圖背景
            Image(.treasureMap)
                .resizable()

            // 地圖裁切 + 標記
            CroppedMapView(
                imageURL: zone.image,
                normalizedPosition: TreasureSpotMapProjection.normalizedPosition(
                    of: spot,
                    sizeFactor: zone.sizeFactor
                )
            )
            .padding(.horizontal, 22)
            .padding(.vertical, 18)

            // 資訊覆蓋層
            VStack {
                // 上方：編號 + 座標
                HStack(alignment: .top) {
                    Text("\(index)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                        .shadow(color: .black, radius: 2)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.TreasureMap.coordinatesXY(x: coordinateText(spot.x), y: coordinateText(spot.y)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .shadow(color: .black, radius: 2)

                        HStack(spacing: 3) {
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 6, height: 6)
                            Text(zone.name)
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .shadow(color: .black, radius: 2)
                        }
                    }
                }

                Spacer()

                // 下方：隊伍人數
                HStack {
                    HStack(spacing: 4) {
                        Image(.treasuremapPlayer)
                            .resizable()
                            .frame(width: 18, height: 18)
                        Text("\(partySize)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .shadow(color: .black, radius: 2)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 24)
        }
        .aspectRatio(4.0 / 3.5, contentMode: .fit)
    }
}

// MARK: - 地圖裁切視圖

enum TreasureSpotMapProjection {
    /// The spot's position on its map image, from 0 to 1 on each axis. Map coordinates run from 1
    /// to 1 + 41 / (size factor / 100), so a map with a size factor other than 100 is scaled too.
    static func normalizedPosition(of spot: TreasureSpot, sizeFactor: Int) -> CGPoint {
        GatheringMapProjection.position(x: spot.x, y: spot.y, sizeFactor: sizeFactor, mapSize: 1)
    }
}

private struct CroppedMapView: View {
    let imageURL: String
    let normalizedPosition: CGPoint

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            // 完整地圖放大到裁切範圍的 5 倍（顯示約 20% 的地圖）
            let scale: CGFloat = 5.0
            let mapSize = max(size.width, size.height) * scale
            let offsetX = size.width / 2 - normalizedPosition.x * mapSize
            let offsetY = size.height / 2 - normalizedPosition.y * mapSize

            if let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .frame(width: mapSize, height: mapSize)
                            .offset(x: offsetX, y: offsetY)
                    case .failure:
                        placeholder
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipped()
        .overlay {
            Image(.treasureMarker)
                .resizable()
                .frame(width: 28, height: 28)
        }
    }

    private var placeholder: some View {
        Color.brown.opacity(0.2)
            .overlay {
                ProgressView()
            }
    }
}
