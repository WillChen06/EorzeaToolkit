import SwiftUI
import SwiftData
import ComposableArchitecture

extension RelicWeaponSeriesFeature.Mode: Identifiable {
    var id: Self { self }

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
    @State private var store: StoreOf<RelicWeaponFeature>
    
    let onReturnHome: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RelicWeaponViewModel()
    
    init(
        store: StoreOf<RelicWeaponFeature> = Store(initialState: RelicWeaponFeature.State()) {
            RelicWeaponFeature()
        },
        onReturnHome: @escaping () -> Void = {}
    ) {
        _store = State(initialValue: store)
        self.onReturnHome = onReturnHome
    }

    var body: some View {
        FeatureNavigationView(feature: .relicWeapon, selectionID: store.selectedSeriesID, onReturnHome: onReturnHome) {
            sidebar
        } detail: {
            if let detailStore = store.scope(state: \.seriesDetail, action: \.seriesDetail) {
                RelicWeaponSeriesView(store: detailStore, viewModel: viewModel)
            }
        }
        .task {
            store.send(.task)
            
            // 詳細頁的進度還在 ViewModel，等子 Reducer 和進度 client 完成後再移除
            if !viewModel.hasLoadedWeapons {
                viewModel.configure(modelContext: modelContext)
                viewModel.loadWeapons()
            }
        }
    }

    private var sidebar: some View {
        Group {
            switch store.loadState {
            case .idle, .loading:
                ProgressView(L10n.RelicWeapon.loading)
            case .loaded:
                if store.weaponSeriesList.isEmpty {
                    ContentUnavailableView(
                        L10n.RelicWeapon.emptyTitle,
                        systemImage: "sparkles",
                        description: Text(L10n.RelicWeapon.emptyDescription)
                    )
                } else {
                    List(store.weaponSeriesList, selection: $store.selectedSeriesID.sending(\.seriesSelected)) { series in
                        NavigationLink(value: series.id) {
                            RelicWeaponSeriesRow(
                                series: series,
                                isLatest: series.id == store.weaponSeriesList.last?.id
                            )
                        }
                        .appThemedListRow()
                    }
                    .listStyle(.insetGrouped)
                    .appThemedScrollContent()
                }
            case let .failed(loadError):
                ContentUnavailableView(
                    L10n.RelicWeapon.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            }
        }
        .navigationTitle(L10n.RelicWeapon.title)
        .navigationBarTitleDisplayMode(.inline)
        .appThemedBackground()
        .appThemedScreen(tint: HomeFeature.relicWeapon.accent)
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
                .foregroundStyle(AppTheme.aetherBlue)

            Text(L10n.RelicWeapon.level(series.levelCap))
                .font(.caption.bold())
                .foregroundStyle(AppTheme.mutedInk)
        }
        .frame(width: 56, height: 56)
        .background(AppTheme.aetherBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppTheme.aetherBlue.opacity(0.28), lineWidth: 1)
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            Text(series.expansion)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)

            metadataText(L10n.RelicWeapon.stageCount(series.stages.count))
            metadataText(L10n.RelicWeapon.jobCount(series.availableJobs.count))
        }
    }

    private var latestBadge: some View {
        Text(L10n.RelicWeapon.latest)
            .font(.caption.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(AppTheme.aetherBlue)
            .background(AppTheme.aetherBlue.opacity(0.12), in: Capsule())
    }

    private func metadataText(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppTheme.mutedInk)
    }
}

private struct RelicWeaponSeriesView: View {
    @Bindable var store: StoreOf<RelicWeaponSeriesFeature>
    let viewModel: RelicWeaponViewModel
    @State private var expandedStageIndices: Set<Int> = []

    var body: some View {
        List {
            Section {
                Picker(L10n.RelicWeapon.mode, selection: $store.selectedMode.sending(\.modeSelected)) {
                    ForEach(RelicWeaponSeriesFeature.Mode.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            .appThemedListRow()

            if store.selectedMode == .tracking {
                trackingSummarySection
            }

            Section(L10n.RelicWeapon.stagesSection) {
                ForEach(store.series.stages) { stage in
                    RelicWeaponStageDisclosureView(
                        stage: stage,
                        isTrackingEnabled: store.selectedMode == .tracking,
                        isCompleted: viewModel.isStageCompleted(stage, for: store.series.id, job: store.selectedJob),
                        isExpanded: binding(for: stage),
                        toggleCompletion: {
                            viewModel.toggleStage(stage, for: store.series.id, job: store.selectedJob)
                        }
                    )
                }
            }
            .appThemedListRow()
        }
        .listStyle(.insetGrouped)
        .appThemedScrollContent()
        .navigationTitle(L10n.RelicWeapon.seriesTitle(shortName: store.series.nameTw, fullName: store.series.fullNameTw))
        .navigationBarTitleDisplayMode(.inline)
        .appThemedScreen(tint: HomeFeature.relicWeapon.accent)
    }

    private var trackingSummarySection: some View {
        Section {
            Picker(L10n.RelicWeapon.job, selection: $store.selectedJob.sending(\.jobSelected)) {
                ForEach(store.series.availableJobs, id: \.self) { job in
                    Text(L10n.RelicWeapon.jobName(job)).tag(job)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                let completedCount = viewModel.completedStageCount(for: store.series.id, job: store.selectedJob)
                let totalCount = store.series.stages.count
                let percentage = totalCount == 0 ? 0 : Int((Double(completedCount) / Double(totalCount) * 100).rounded())

                HStack {
                    Text(L10n.RelicWeapon.progress)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(L10n.RelicWeapon.progressSummary(completedCount: completedCount, totalCount: totalCount, percentage: percentage))
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedInk)
                }

                ProgressView(value: Double(completedCount), total: Double(max(totalCount, 1)))
                    .tint(.green)
            }
            .padding(.vertical, 4)
        }
        .appThemedListRow()
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
}

#Preview {
    RelicWeaponListView()
    .modelContainer(for: RelicWeaponProgress.self, inMemory: true)
}
