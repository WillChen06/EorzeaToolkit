import SwiftUI

private enum RelicWeaponMode: CaseIterable, Identifiable {
    case view
    case tracking

    var id: String {
        switch self {
        case .view:
            "view"
        case .tracking:
            "tracking"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .view:
            L10n.RelicWeapon.modeView
        case .tracking:
            L10n.RelicWeapon.modeTracking
        }
    }
}

struct RelicWeaponListView: View {
    @State private var viewModel = RelicWeaponViewModel()

    var body: some View {
        Group {
            if let loadError = viewModel.loadError {
                ContentUnavailableView(
                    L10n.RelicWeapon.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if !viewModel.weaponSeriesList.isEmpty {
                List(Array(viewModel.weaponSeriesList.enumerated()), id: \.element.id) { index, series in
                    NavigationLink(destination: RelicWeaponSeriesView(series: series, viewModel: viewModel)) {
                        RelicWeaponSeriesRow(
                            series: series,
                            isLatest: index == viewModel.weaponSeriesList.count - 1
                        )
                    }
                }
                .listStyle(.insetGrouped)
            } else if viewModel.hasLoadedWeapons {
                ContentUnavailableView(
                    L10n.RelicWeapon.emptyTitle,
                    systemImage: "sparkles",
                    description: Text(L10n.RelicWeapon.emptyDescription)
                )
            } else {
                ProgressView(L10n.RelicWeapon.loading)
            }
        }
        .navigationTitle(L10n.RelicWeapon.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadWeapons()
        }
    }
}

private struct RelicWeaponSeriesRow: View {
    let series: WeaponSeries
    let isLatest: Bool

    var body: some View {
        HStack(spacing: 14) {
            seriesBadge

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(series.fullNameTw)
                        .font(.headline)
                        .lineLimit(1)

                    if isLatest {
                        latestBadge
                    }
                }

                metadataRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
    }

    private var seriesBadge: some View {
        VStack(spacing: 2) {
            Text(series.nameTw)
                .font(.headline.weight(.bold))
                .foregroundStyle(HomeStyle.aetherBlue)

            Text(L10n.RelicWeapon.level(series.levelCap))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 56, height: 56)
        .background(HomeStyle.aetherBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(HomeStyle.aetherBlue.opacity(0.28), lineWidth: 1)
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            Text(series.expansion)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            metadataText(L10n.RelicWeapon.stageCount(series.stages.count))
            metadataText(L10n.RelicWeapon.jobCount(series.availableJobs.count))
        }
    }

    private var latestBadge: some View {
        Text(L10n.RelicWeapon.latest)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(HomeStyle.aetherBlue)
            .background(HomeStyle.aetherBlue.opacity(0.12), in: Capsule())
    }

    private func metadataText(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
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
                Picker(L10n.RelicWeapon.mode, selection: $mode) {
                    ForEach(RelicWeaponMode.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            if mode == .tracking {
                trackingSummarySection
            }

            Section(L10n.RelicWeapon.stagesSection) {
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
        .navigationTitle(L10n.RelicWeapon.seriesTitle(shortName: series.nameTw, fullName: series.fullNameTw))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateSelectedJobIfNeeded()
        }
    }

    private var trackingSummarySection: some View {
        Section {
            Picker(L10n.RelicWeapon.job, selection: $selectedJob) {
                ForEach(series.availableJobs, id: \.self) { job in
                    Text(L10n.RelicWeapon.jobName(job)).tag(job)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                let completedCount = viewModel.completedStageCount(for: series.id, job: selectedJob)
                let totalCount = series.stages.count
                let percentage = totalCount == 0 ? 0 : Int((Double(completedCount) / Double(totalCount) * 100).rounded())

                HStack {
                    Text(L10n.RelicWeapon.progress)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(L10n.RelicWeapon.progressSummary(completedCount: completedCount, totalCount: totalCount, percentage: percentage))
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

#Preview {
    NavigationStack {
        RelicWeaponListView()
    }
}
