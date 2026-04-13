import SwiftUI

struct GatheringNodesSheetView: View {
    let map: TreasureMap
    let nodes: [GatheringNodeDisplay]
    @Environment(\.dismiss) private var dismiss

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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
}
