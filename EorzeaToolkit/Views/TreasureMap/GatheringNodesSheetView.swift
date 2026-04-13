import SwiftUI

struct GatheringNodesSheetView: View {
    let map: TreasureMap
    let nodes: [GatheringNodeDisplay]
    let viewModel: TreasureMapViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNode: GatheringNodeDisplay?

    private var minerNodes: [GatheringNodeDisplay] {
        nodes.filter { $0.job == .miner }
    }

    private var botanistNodes: [GatheringNodeDisplay] {
        nodes.filter { $0.job == .botanist }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !minerNodes.isEmpty {
                        jobSection(job: .miner, nodes: minerNodes)
                    }
                    if !botanistNodes.isEmpty {
                        jobSection(job: .botanist, nodes: botanistNodes)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(map.grade) - \(map.name) (Lv.\(map.level) 採集點)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Color(.systemGray4))
                            .clipShape(Circle())
                    }
                }
            }
            .fullScreenCover(item: $selectedNode) { node in
                GatheringNodeMapView(node: node, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func jobSection(job: GatheringJob, nodes: [GatheringNodeDisplay]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(job.label) (\(nodes.count)個)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.sRGB, red: 0.82, green: 0.7, blue: 0.42))

            Divider()
                .overlay(Color(.sRGB, red: 0.82, green: 0.7, blue: 0.42).opacity(0.3))

            VStack(spacing: 1) {
                ForEach(nodes) { node in
                    nodeRow(node)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func nodeRow(_ node: GatheringNodeDisplay) -> some View {
        HStack(spacing: 12) {
            Text(node.typeName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(node.typeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(node.typeColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(node.zoneName)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Text("(\(node.x, specifier: "%.1f"), \(node.y, specifier: "%.1f"))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                selectedNode = node
            } label: {
                Image(systemName: "map")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - 採集點地圖視圖

struct GatheringNodeMapView: View {
    let node: GatheringNodeDisplay
    let viewModel: TreasureMapViewModel
    @Environment(\.dismiss) private var dismiss

    private var mapInfo: MapInfo? {
        viewModel.mapInfo(forZoneId: node.zoneId)
    }

    private var normalizedX: Double {
        let sizeFactor = Double(mapInfo?.sizeFactor ?? 100)
        return (node.x - 1) * sizeFactor / 100.0 / 41.0
    }

    private var normalizedY: Double {
        let sizeFactor = Double(mapInfo?.sizeFactor ?? 100)
        return (node.y - 1) * sizeFactor / 100.0 / 41.0
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 標題
                HStack {
                    Text("\(node.zoneName) - \(node.typeName)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding()

                // 地圖
                GeometryReader { geo in
                    let mapSize = min(geo.size.width, geo.size.height)

                    ZStack {
                        if let imageURL = mapInfo.flatMap({ URL(string: $0.image) }) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(1, contentMode: .fit)
                                case .failure:
                                    mapPlaceholder
                                default:
                                    mapPlaceholder
                                }
                            }
                        } else {
                            mapPlaceholder
                        }

                        // 範圍圓圈 + 標記
                        markerOverlay(mapSize: mapSize)
                    }
                    .frame(width: mapSize, height: mapSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // 資訊
                VStack(spacing: 8) {
                    Text("類型：\(node.typeName)")
                        .font(.body)
                        .foregroundStyle(.white)
                    Text("座標：X: \(node.x, specifier: "%.1f"), Y: \(node.y, specifier: "%.1f")")
                        .font(.body)
                        .foregroundStyle(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6).opacity(0.3))
            }

            // 關閉按鈕
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color(.systemGray3).opacity(0.8))
                    .clipShape(Circle())
            }
            .padding()
        }
    }

    private func markerOverlay(mapSize: CGFloat) -> some View {
        let markerX = normalizedX * mapSize
        let markerY = normalizedY * mapSize
        let circleRadius: CGFloat = mapSize * 0.08

        return ZStack {
            // 範圍圓圈
            Circle()
                .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                .fill(Color.cyan.opacity(0.15))
                .frame(width: circleRadius * 2, height: circleRadius * 2)
                .position(x: markerX, y: markerY)

            // 採集點圖標
            if let iconURL = node.typeIconURL {
                AsyncImage(url: iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .frame(width: 32, height: 32)
                            .position(x: markerX, y: markerY)
                    default:
                        fallbackMarker
                            .position(x: markerX, y: markerY)
                    }
                }
            } else {
                fallbackMarker
                    .position(x: markerX, y: markerY)
            }
        }
    }

    private var fallbackMarker: some View {
        Circle()
            .fill(node.typeColor)
            .frame(width: 16, height: 16)
    }

    private var mapPlaceholder: some View {
        Color.brown.opacity(0.3)
            .aspectRatio(1, contentMode: .fit)
            .overlay { ProgressView().tint(.white) }
    }
}
