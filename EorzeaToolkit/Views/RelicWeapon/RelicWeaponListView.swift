import SwiftUI

private enum RelicWeaponMode: String, CaseIterable, Identifiable {
    case view = "檢視"
    case tracking = "追蹤"

    var id: String { rawValue }
}

struct RelicWeaponListView: View {
    @State private var viewModel = RelicWeaponViewModel()

    var body: some View {
        Group {
            if !viewModel.weaponSeriesList.isEmpty {
                List(Array(viewModel.weaponSeriesList.enumerated()), id: \.element.id) { index, series in
                    NavigationLink(destination: RelicWeaponSeriesView(series: series, viewModel: viewModel)) {
                        RelicWeaponSeriesRow(
                            series: series,
                            isLatest: index == viewModel.weaponSeriesList.count - 1
                        )
                    }
                }
                .navigationTitle("發光武器")
            } else if let loadError = viewModel.loadError {
                ContentUnavailableView(
                    "無法載入發光武器資料",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
                .navigationTitle("發光武器")
            } else {
                ProgressView("載入發光武器資料")
                    .navigationTitle("發光武器")
            }
        }
        .task {
            viewModel.loadWeapons()
        }
    }
}

private struct RelicWeaponSeriesRow: View {
    let series: WeaponSeries
    let isLatest: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .center, spacing: 2) {
                Text(series.nameTw)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Lv.\(series.levelCap)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 58)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(series.fullNameTw)
                        .font(.headline)

                    if isLatest {
                        Text("最新")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(.blue)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Text(series.expansion)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(series.stages.count) 個階段")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(series.availableJobs.count) 個職業")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct RelicWeaponSeriesView: View {
    let series: WeaponSeries
    let viewModel: RelicWeaponViewModel

    @State private var mode: RelicWeaponMode = .view
    @State private var selectedJob = ""
    @State private var expandedStageIndices: Set<Int> = []

    var body: some View {
        List {
            Section {
                Picker("模式", selection: $mode) {
                    ForEach(RelicWeaponMode.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            if mode == .tracking {
                trackingSummarySection
            }

            Section("製作階段") {
                ForEach(series.stages) { stage in
                    RelicWeaponStageDisclosureView(
                        stage: stage,
                        isTrackingEnabled: mode == .tracking,
                        isCompleted: viewModel.isStageCompleted(stage, for: series.id, job: selectedJob),
                        isExpanded: binding(for: stage),
                        toggleCompletion: {
                            viewModel.toggleStage(stage, for: series.id, job: selectedJob)
                        }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("發光武器 - \(series.nameTw)（\(series.fullNameTw)）")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateSelectedJobIfNeeded()
        }
    }

    private var trackingSummarySection: some View {
        Section {
            Picker("職業", selection: $selectedJob) {
                ForEach(series.availableJobs, id: \.self) { job in
                    Text(job.displayName).tag(job)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                let completedCount = viewModel.completedStageCount(for: series.id, job: selectedJob)
                let totalCount = series.stages.count
                let percentage = totalCount == 0 ? 0 : Int((Double(completedCount) / Double(totalCount) * 100).rounded())

                HStack {
                    Text("進度")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text("\(completedCount) / \(totalCount) 階段完成 (\(percentage)%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(completedCount), total: Double(max(totalCount, 1)))
                    .tint(.green)
            }
            .padding(.vertical, 4)
        }
    }

    private func binding(for stage: WeaponStage) -> Binding<Bool> {
        Binding(
            get: {
                expandedStageIndices.contains(stage.stageIndex)
            },
            set: { isExpanded in
                if isExpanded {
                    expandedStageIndices.insert(stage.stageIndex)
                } else {
                    expandedStageIndices.remove(stage.stageIndex)
                }
            }
        )
    }

    private func updateSelectedJobIfNeeded() {
        guard !series.availableJobs.isEmpty else {
            selectedJob = ""
            return
        }

        if !series.availableJobs.contains(selectedJob) {
            selectedJob = series.availableJobs[0]
        }
    }
}

private extension String {
    var displayName: String {
        switch self {
        case "PLD":
            "騎士"
        case "WAR":
            "戰士"
        case "DRK":
            "暗黑騎士"
        case "GNB":
            "絕槍戰士"
        case "WHM":
            "白魔法師"
        case "SCH":
            "學者"
        case "AST":
            "占星術士"
        case "SGE":
            "賢者"
        case "MNK":
            "武僧"
        case "DRG":
            "龍騎士"
        case "NIN":
            "忍者"
        case "SAM":
            "武士"
        case "RPR":
            "鐮刀師"
        case "VPR":
            "蝰蛇劍士"
        case "BRD":
            "吟遊詩人"
        case "MCH":
            "機工士"
        case "DNC":
            "舞者"
        case "BLM":
            "黑魔法師"
        case "SMN":
            "召喚師"
        case "RDM":
            "赤魔法師"
        case "PCT":
            "繪靈法師"
        default:
            self
        }
    }
}

#Preview {
    NavigationStack {
        RelicWeaponListView()
    }
}
