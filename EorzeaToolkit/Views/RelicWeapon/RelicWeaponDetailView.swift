import SwiftUI

struct RelicWeaponDetailView: View {
    let weapon: RelicWeapon

    var body: some View {
        List {
            Section("基本資訊") {
                LabeledContent("名稱", value: weapon.name)
                LabeledContent("英文", value: weapon.nameEn)
                LabeledContent("職業", value: weapon.job)
            }

            Section("製作步驟 (\(weapon.steps.count))") {
                ForEach(weapon.steps) { step in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("步驟 \(step.step)：\(step.title)")
                            .font(.headline)
                        Text(step.description)
                            .font(.subheadline)
                        if !step.materials.isEmpty {
                            ForEach(step.materials) { material in
                                Text("· \(material.name) ×\(material.quantity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(weapon.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
