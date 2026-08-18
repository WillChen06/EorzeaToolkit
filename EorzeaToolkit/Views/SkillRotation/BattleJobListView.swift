import SwiftUI

struct BattleJobListView: View {
    @State private var viewModel = SkillRotationViewModel()

    var body: some View {
        Group {
            if let loadError = viewModel.loadError {
                ContentUnavailableView(
                    L10n.SkillRotation.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if !viewModel.jobs.isEmpty {
                List(viewModel.jobs) { job in
                    NavigationLink {
                        SkillRotationEditorView(job: job, viewModel: viewModel)
                    } label: {
                        HStack(spacing: 14) {
                            CachedIconImage(url: job.iconURL) {
                                placeholder
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(AppTheme.crystal.opacity(0.24), lineWidth: 1)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(job.displayName)
                                    .font(.headline)
                                Text(job.abbreviation)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.mutedInk)
                            }

                            Spacer()

                            let savedLevels = viewModel.savedLevels(for: job.id)
                            if !savedLevels.isEmpty {
                                Text(savedLevels.map { $0.label }.joined(separator: " / "))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.crystal.opacity(0.14), in: Capsule())
                                    .foregroundStyle(AppTheme.crystal)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .appThemedListRow()
                }
                .listStyle(.insetGrouped)
                .appThemedScrollContent()
            } else if viewModel.hasLoadedJobs {
                ContentUnavailableView(
                    L10n.SkillRotation.emptyTitle,
                    systemImage: "bolt.circle",
                    description: Text(L10n.SkillRotation.emptyDescription)
                )
            } else {
                ProgressView(L10n.SkillRotation.loading)
            }
        }
        .navigationTitle(L10n.SkillRotation.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
        .appThemedBackground()
        .appThemedScreen(tint: HomeFeature.skillRotation.accent)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(AppTheme.crystal.opacity(0.10))
            .overlay {
                Image(systemName: "bolt.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.crystal)
            }
    }
}

#Preview {
    NavigationStack {
        BattleJobListView()
    }
}
