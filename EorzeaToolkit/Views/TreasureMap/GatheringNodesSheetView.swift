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
            .appThemedBackground()
            .navigationTitle(L10n.TreasureMap.gatheringSheetTitle(grade: map.grade, name: map.name, level: map.level))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done, systemImage: "xmark", action: dismiss.callAsFunction)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(HomeFeature.treasureMap.accent)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.surfaceDepth, in: Circle())
                }
            }
            .fullScreenCover(item: $selectedNode) { node in
                GatheringNodeMapView(node: node, viewModel: viewModel)
            }
            .appThemedScreen(tint: HomeFeature.treasureMap.accent)
        }
    }

    @ViewBuilder
    private func jobSection(job: GatheringJob, nodes: [GatheringNodeDisplay]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.TreasureMap.jobSection(jobLabel: job.label, count: nodes.count))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.gold)

            Divider()
                .overlay(AppTheme.gold.opacity(0.3))

            VStack(spacing: 1) {
                ForEach(nodes) { node in
                    nodeRow(node)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(12)
        .appThemedCard()
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
                .foregroundStyle(AppTheme.ink)

            Spacer()

            Text(L10n.TreasureMap.coordinatePair(x: coordinateText(node.x), y: coordinateText(node.y)))
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)

            Button(L10n.TreasureMap.gatheringNodes, systemImage: "map") {
                selectedNode = node
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(HomeFeature.treasureMap.accent)
            .frame(width: 44, height: 44)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(AppTheme.surface)
    }
}

// MARK: - 採集點地圖視圖

struct GatheringNodeMapView: View {
    let node: GatheringNodeDisplay
    let viewModel: TreasureMapViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var minimumMapWidth = 320.0
    @ScaledMetric(relativeTo: .body) private var minimumInformationWidth = 240.0

    private var mapInfo: MapInfo? {
        viewModel.mapInfo(forZoneId: node.zoneId)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: dismiss.callAsFunction) {
                        Label(L10n.Common.done, systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.8), in: Circle())
                }
                .padding(.bottom, 8)

                GeometryReader { geometry in
                    let policy = GatheringNodeMapLayout(
                        availableSize: geometry.size,
                        minimumMapWidth: minimumMapWidth,
                        minimumInformationWidth: minimumInformationWidth,
                        isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
                    )
                    let layout = policy.isHorizontal
                        ? AnyLayout(HStackLayout(alignment: .top, spacing: policy.spacing))
                        : AnyLayout(VStackLayout(alignment: .leading, spacing: policy.spacing))

                    layout {
                        mapViewport
                            .frame(width: policy.mapSize.width, height: policy.mapSize.height)
                        informationPanel
                            .frame(width: policy.informationSize.width, height: policy.informationSize.height)
                    }
                }
            }
            .padding()
        }
    }

    private var mapViewport: some View {
        GeometryReader { geometry in
            let mapSize = GatheringNodeMapLayout.squareSide(in: geometry.size)
            ZStack {
                if let imageURL = mapInfo.flatMap({ URL(string: $0.image) }) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(1, contentMode: .fit)
                        default:
                            mapPlaceholder
                        }
                    }
                } else {
                    mapPlaceholder
                }
                markerOverlay(mapSize: mapSize)
            }
            .frame(width: mapSize, height: mapSize)
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var informationPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.TreasureMap.nodeMapTitle(zoneName: node.zoneName, typeName: node.typeName))
                    .font(.title3)
                    .fontWeight(.bold)
                Text(L10n.TreasureMap.nodeType(node.typeName))
                    .font(.body)
                Text(L10n.TreasureMap.nodeCoordinates(x: coordinateText(node.x), y: coordinateText(node.y)))
                    .font(.body)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .foregroundStyle(.white)
        .background(.black.opacity(0.6))
    }

    private func markerOverlay(mapSize: CGFloat) -> some View {
        let marker = GatheringMapProjection.position(x: node.x, y: node.y, sizeFactor: mapInfo?.sizeFactor, mapSize: mapSize)
        let markerX = marker.x
        let markerY = marker.y
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
                CachedIconImage(url: iconURL) {
                    fallbackMarker
                }
                .frame(width: 32, height: 32)
                .position(x: markerX, y: markerY)
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

func coordinateText(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(1)))
}
