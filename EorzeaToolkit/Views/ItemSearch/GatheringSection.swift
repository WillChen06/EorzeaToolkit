import SwiftUI

struct GatheringSection: View {
    let nodes: [ItemGatheringNode]
    let fishingSpots: [ItemFishingSpot]

    @State private var isExpanded = false

    private let collapsedLimit = 3

    var body: some View {
        if totalCount > 0 {
            Section(L10n.ItemSearch.Gathering.section) {
                ForEach(visibleRows) { row in
                    switch row.content {
                    case .gathering(let node):
                        GatheringNodeCard(node: node)
                    case .fishing(let spot):
                        FishingSpotCard(spot: spot)
                    }
                }

                if shouldShowToggle {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Label(toggleTitle, systemImage: isExpanded ? "chevron.up" : "chevron.down")

                            Spacer(minLength: 8)

                            Text("\(totalCount)")
                                .monospacedDigit()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text(isExpanded ? L10n.ItemSearch.Gathering.collapseHint : L10n.ItemSearch.Gathering.showAllHint))
                }
            }
        }
    }

    private var allRows: [GatheringDisplayRow] {
        var occurrenceCounts: [GatheringDisplayContent: Int] = [:]

        let contents = nodes.map(GatheringDisplayContent.gathering) +
            fishingSpots.map(GatheringDisplayContent.fishing)

        return contents.map { content in
            let occurrence = occurrenceCounts[content, default: 0]
            occurrenceCounts[content] = occurrence + 1

            return GatheringDisplayRow(
                id: "\(content.stableDisplayID)#\(occurrence)",
                content: content
            )
        }
    }

    private var visibleRows: [GatheringDisplayRow] {
        if isExpanded {
            return allRows
        }

        return Array(allRows.prefix(collapsedLimit))
    }

    private var totalCount: Int {
        nodes.count + fishingSpots.count
    }

    private var shouldShowToggle: Bool {
        totalCount > collapsedLimit
    }

    private var toggleTitle: LocalizedStringKey {
        isExpanded ? L10n.ItemSearch.Gathering.collapse : L10n.ItemSearch.Gathering.showAll
    }
}

private struct GatheringDisplayRow: Identifiable {
    let id: String
    let content: GatheringDisplayContent
}

private enum GatheringDisplayContent: Hashable {
    case gathering(ItemGatheringNode)
    case fishing(ItemFishingSpot)

    var stableDisplayID: String {
        switch self {
        case .gathering(let node):
            return "gathering|\(node.stableDisplayID)"
        case .fishing(let spot):
            return "fishing|\(spot.stableDisplayID)"
        }
    }
}

private struct GatheringNodeCard: View {
    let node: ItemGatheringNode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(node.job)・\(node.method)")
                    .font(.headline)

                Spacer(minLength: 12)

                Text("Lv.\(node.level)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Label(node.locationText, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !node.traitLabels.isEmpty {
                HStack(spacing: 6) {
                    ForEach(node.traitLabels, id: \.self) { label in
                        GatheringTraitBadge(label: label)
                    }
                }
            }

            if let spawnTimeText = node.spawnTimeText {
                Label(spawnTimeText, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

private extension ItemGatheringNode {
    var stableDisplayID: String {
        [
            job,
            method,
            "\(level)",
            "\(zoneID)",
            zoneName,
            "\(x)",
            "\(y)",
            "\(mapID)",
            "\(isHidden)",
            "\(isLegendary)",
            "\(isEphemeral)",
            "\(isLimited)",
            spawns.map(String.init).joined(separator: ","),
            "\(duration)"
        ].joined(separator: "|")
    }
}

private struct GatheringTraitBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}

private struct FishingSpotCard: View {
    let spot: ItemFishingSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(spot.job)・\(spot.method)")
                    .font(.headline)

                Spacer(minLength: 12)

                Text(spot.levelText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if !conditions.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        conditionBadges
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        conditionBadges
                    }
                }
            }

            Label(spot.locationText, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let url = spot.teamcraftLinkURL {
                Link(destination: url) {
                    Label(L10n.ItemSearch.Gathering.openFishingGuide, systemImage: "arrow.up.forward.square")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint(Text(L10n.ItemSearch.Gathering.openFishingGuideHint))
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var conditionBadges: some View {
        ForEach(conditions) { condition in
            FishingConditionBadge(condition: condition)
        }
    }

    private var conditions: [FishingCondition] {
        var conditions: [FishingCondition] = []

        if spot.isTimed {
            conditions.append(.timed)
        }

        if spot.isWeathered {
            conditions.append(.weathered)
        }

        if spot.hasFolklore {
            conditions.append(.folklore)
        }

        return conditions
    }
}

private enum FishingCondition: String, Identifiable {
    case timed = "限時"
    case weathered = "限天氣"
    case folklore = "需釣魚筆記"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .timed:
            return "clock"
        case .weathered:
            return "cloud.sun"
        case .folklore:
            return "book.closed"
        }
    }

    var tint: Color {
        switch self {
        case .timed:
            return .cyan
        case .weathered:
            return .purple
        case .folklore:
            return .orange
        }
    }
}

private struct FishingConditionBadge: View {
    let condition: FishingCondition

    var body: some View {
        Label(condition.rawValue, systemImage: condition.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(condition.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(condition.tint.opacity(0.14), in: Capsule())
    }
}

private extension ItemFishingSpot {
    var stableDisplayID: String {
        [
            job,
            method,
            "\(level)",
            "\(stars)",
            "\(zoneID)",
            zoneName,
            "\(x)",
            "\(y)",
            "\(mapID)",
            "\(isTimed)",
            "\(isWeathered)",
            "\(hasFolklore)",
            teamcraftURL
        ].joined(separator: "|")
    }
}
