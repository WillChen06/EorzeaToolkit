import SwiftUI

struct TreasureSpotListView: View {
    let zoneName: String
    let spots: [TreasureSpot]
    let mapImageURL: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                    TreasureSpotCard(
                        index: index + 1,
                        spot: spot,
                        zoneName: zoneName,
                        mapImageURL: mapImageURL
                    )
                }
            }
            .padding()
        }
        .navigationTitle(zoneName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - 點位卡片

private struct TreasureSpotCard: View {
    let index: Int
    let spot: TreasureSpot
    let zoneName: String
    let mapImageURL: String?

    var body: some View {
        ZStack {
            // 藏寶圖背景
            Image("treasure_map")
                .resizable()

            // 地圖裁切 + 標記
            CroppedMapView(
                imageURL: mapImageURL,
                normalizedX: (spot.coords.x - 1) / 41.0,
                normalizedY: (spot.coords.y - 1) / 41.0
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
                        Text("X: \(spot.coords.x, specifier: "%.1f") Y: \(spot.coords.y, specifier: "%.1f")")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .shadow(color: .black, radius: 2)

                        HStack(spacing: 3) {
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 6, height: 6)
                            Text(zoneName)
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
                        Image("treasuremap_player")
                            .resizable()
                            .frame(width: 18, height: 18)
                        Text("\(spot.partySize)")
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

private struct CroppedMapView: View {
    let imageURL: String?
    let normalizedX: Double
    let normalizedY: Double

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            // 完整地圖放大到裁切範圍的 5 倍（顯示約 20% 的地圖）
            let scale: CGFloat = 5.0
            let mapSize = max(size.width, size.height) * scale
            let offsetX = size.width / 2 - normalizedX * mapSize
            let offsetY = size.height / 2 - normalizedY * mapSize

            if let url = imageURL.flatMap({ URL(string: $0) }) {
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
            Image("treasure_marker")
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
