import SwiftUI

struct TreasureMapDetailView: View {
    let map: TreasureMap

    var body: some View {
        List {
            Section("基本資訊") {
                LabeledContent("名稱", value: map.name)
                LabeledContent("英文", value: map.nameEn)
                LabeledContent("日文", value: map.nameJa)
                LabeledContent("等級", value: "Lv.\(map.level)")
            }

            Section("地點 (\(map.locations.count))") {
                ForEach(map.locations) { location in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(location.zone)
                            .font(.headline)
                        Text(location.zoneEn)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("X: \(location.coordinates.x, specifier: "%.1f"), Y: \(location.coordinates.y, specifier: "%.1f")")
                            .font(.caption)
                            .monospaced()
                        if !location.notes.isEmpty {
                            Text(location.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(map.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
