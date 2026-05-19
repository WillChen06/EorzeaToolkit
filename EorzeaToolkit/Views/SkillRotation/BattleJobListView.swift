import SwiftUI

struct BattleJobListView: View {
    @State private var viewModel = SkillRotationViewModel()

    var body: some View {
        Group {
            if let loadError = viewModel.loadError {
                ContentUnavailableView(
                    "無法載入技能資料",
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
                                    .strokeBorder(HomeStyle.crystal.opacity(0.24), lineWidth: 1)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(job.displayName)
                                    .font(.headline)
                                Text(job.abbreviation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                                    .background(HomeStyle.crystal.opacity(0.14), in: Capsule())
                                    .foregroundStyle(HomeStyle.crystal)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.insetGrouped)
            } else if viewModel.hasLoadedJobs {
                ContentUnavailableView(
                    "尚無技能資料",
                    systemImage: "bolt.circle",
                    description: Text("目前沒有可顯示的職業")
                )
            } else {
                ProgressView("載入技能資料")
            }
        }
        .navigationTitle("技能循環")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(HomeStyle.crystal.opacity(0.10))
            .overlay {
                Image(systemName: "bolt.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(HomeStyle.crystal)
            }
    }
}

#Preview {
    NavigationStack {
        BattleJobListView()
    }
}
