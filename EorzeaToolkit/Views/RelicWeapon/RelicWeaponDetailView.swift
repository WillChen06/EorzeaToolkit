import SwiftUI

struct RelicWeaponStageDisclosureView: View {
    let stage: WeaponStage
    let isTrackingEnabled: Bool
    let isCompleted: Bool
    @Binding var isExpanded: Bool
    let toggleCompletion: () -> Void

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            RelicWeaponStageDetailView(stage: stage)
                .padding(.top, 8)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                if isTrackingEnabled {
                    Button {
                        toggleCompletion()
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isCompleted ? "標記為未完成" : "標記為完成")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.nameTw.replacingOccurrences(of: " / ", with: " "))
                        .font(.headline)

                    Text("階段 \(stage.stageIndex)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(stage.ilvlLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.vertical, 4)
        }
    }
}

private struct RelicWeaponStageDetailView: View {
    let stage: WeaponStage
    @State private var expandedMaterialIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !stage.taskDescriptionTw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("任務")
                        .font(.subheadline.weight(.semibold))

                    Text(stage.taskDescriptionTw)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("素材")
                    .font(.subheadline.weight(.semibold))

                if stage.materials.isEmpty {
                    Text("無需額外素材")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stage.materials) { material in
                        RelicWeaponMaterialRow(
                            material: material,
                            isNoteExpanded: expandedMaterialIDs.contains(material.id),
                            toggleNote: {
                                toggleNote(for: material)
                            }
                        )
                    }
                }
            }
        }
        .padding(.leading, 2)
    }

    private func toggleNote(for material: WeaponMaterial) {
        if expandedMaterialIDs.contains(material.id) {
            expandedMaterialIDs.remove(material.id)
        } else {
            expandedMaterialIDs.insert(material.id)
        }
    }
}

private struct RelicWeaponMaterialRow: View {
    let material: WeaponMaterial
    let isNoteExpanded: Bool
    let toggleNote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .foregroundStyle(.secondary)

                Text(material.displayText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if material.hasNote {
                    Button {
                        toggleNote()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .accessibilityLabel(isNoteExpanded ? "隱藏取得備註" : "顯示取得備註")
                }
            }

            if isNoteExpanded, let noteTw = material.normalizedNoteTw {
                Text(noteTw)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 18)
            }
        }
    }
}

private extension WeaponStage {
    var ilvlLabel: String {
        guard let ilvl else {
            return "iLv --"
        }

        return "iLv \(ilvl)"
    }
}

private extension WeaponMaterial {
    var hasNote: Bool {
        normalizedNoteTw != nil
    }

    var normalizedNoteTw: String? {
        let trimmedNote = noteTw?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNote?.isEmpty == false ? trimmedNote : nil
    }

    var displayText: String {
        let baseText: String

        switch quantity {
        case .none:
            baseText = nameTw
        case .number(let value):
            baseText = "\(nameTw) ×\(value)"
        case .text(let value):
            baseText = "\(nameTw) \(value)"
        }

        guard let sourceTw, !sourceTw.isEmpty else {
            return baseText
        }

        return "\(baseText) [\(sourceTw)]"
    }
}
