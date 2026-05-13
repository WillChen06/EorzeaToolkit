import SwiftUI

private enum RelicWeaponMode: String, CaseIterable, Identifiable {
    case view = "檢視"
    case tracking = "追蹤"

    var id: String { rawValue }
}

struct RelicWeaponListView: View {
    @State private var viewModel = RelicWeaponViewModel()
    @State private var mode: RelicWeaponMode = .view
    @State private var selectedJob = ""
    @State private var expandedStageIndices: Set<Int> = []

    var body: some View {
        Group {
            if let series = viewModel.weaponSeries {
                List {
                    Section {
                        Picker("模式", selection: $mode) {
                            ForEach(RelicWeaponMode.allCases) { option in
                                Text(option.rawValue).tag(option)
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if mode == .tracking {
                        trackingSummarySection(for: series)
                    }

                    Section("製作階段") {
                        ForEach(series.stages) { stage in
                            RelicWeaponStageDisclosureView(
                                stage: stage,
                                isTrackingEnabled: mode == .tracking,
                                isCompleted: viewModel.isStageCompleted(stage, for: selectedJob),
                                isExpanded: binding(for: stage),
                                toggleCompletion: {
                                    viewModel.toggleStage(stage, for: selectedJob)
                                }
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("發光武器 - \(series.nameTw)（\(series.fullNameTw)）")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    updateSelectedJobIfNeeded(for: series)
                }
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
            if let series = viewModel.weaponSeries {
                updateSelectedJobIfNeeded(for: series)
            }
        }
    }

    @ViewBuilder
    private func trackingSummarySection(for series: WeaponSeries) -> some View {
        Section {
            Picker("職業", selection: $selectedJob) {
                ForEach(series.availableJobs, id: \.self) { job in
                    Text(job.displayName).tag(job)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                let completedCount = viewModel.completedStageCount(for: selectedJob)
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

    private func updateSelectedJobIfNeeded(for series: WeaponSeries) {
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
        case "WHM":
            "白魔法師"
        case "SCH":
            "學者"
        case "MNK":
            "武僧"
        case "DRG":
            "龍騎士"
        case "NIN":
            "忍者"
        case "BRD":
            "吟遊詩人"
        case "BLM":
            "黑魔法師"
        case "SMN":
            "召喚師"
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
