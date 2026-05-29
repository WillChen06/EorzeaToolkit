import SwiftUI

struct GatheringSection: View {
    let nodes: [ItemGatheringNode]

    @State private var isExpanded = false

    private let collapsedLimit = 3

    var body: some View {
        if !nodes.isEmpty {
            Section("採集") {
                ForEach(visibleRows) { row in
                    GatheringNodeCard(node: row.node)
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

                            Text("\(nodes.count)")
                                .monospacedDigit()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(isExpanded ? "收起採集地點清單" : "展開全部採集地點")
                }
            }
        }
    }

    private var visibleNodes: [ItemGatheringNode] {
        if isExpanded {
            return nodes
        }

        return Array(nodes.prefix(collapsedLimit))
    }

    private var visibleRows: [GatheringNodeRow] {
        var occurrenceCounts: [ItemGatheringNode: Int] = [:]

        return visibleNodes.map { node in
            let occurrence = occurrenceCounts[node, default: 0]
            occurrenceCounts[node] = occurrence + 1

            return GatheringNodeRow(
                id: "\(node.stableDisplayID)#\(occurrence)",
                node: node
            )
        }
    }

    private var shouldShowToggle: Bool {
        nodes.count > collapsedLimit
    }

    private var toggleTitle: String {
        isExpanded ? "收起採集地點" : "顯示全部採集地點"
    }
}

private struct GatheringNodeRow: Identifiable {
    let id: String
    let node: ItemGatheringNode
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
