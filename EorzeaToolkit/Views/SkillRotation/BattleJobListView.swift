import SwiftUI
import ComposableArchitecture

struct BattleJobListView: View {
    @State private var store: StoreOf<SkillRotationFeature>
    let onReturnHome: () -> Void
    
    init(
        store: StoreOf<SkillRotationFeature> = Store(initialState: SkillRotationFeature.State()) {
            SkillRotationFeature()
        },
        onReturnHome: @escaping () -> Void = {}
    ) {
        _store = State(initialValue: store)
        self.onReturnHome = onReturnHome
    }

    var body: some View {
        FeatureNavigationView(feature: .skillRotation, selectionID: store.selectedJobID, onReturnHome: onReturnHome) {
            sidebar
        } detail: {
            if let detailStore = store.scope(state: \.editor, action: \.editor) {
                SkillRotationEditorView(store: detailStore)
            }
        }
        .task {
            store.send(.task)
        }
    }

    private var sidebar: some View {
        Group {
            switch store.loadState {
            case .idle, .loading:
                ProgressView(L10n.SkillRotation.loading)
            case .loaded:
                if store.jobs.isEmpty {
                    ContentUnavailableView(
                        L10n.SkillRotation.emptyTitle,
                        systemImage: "bolt.circle",
                        description: Text(L10n.SkillRotation.emptyDescription)
                    )
                } else {
                    List(store.jobs, selection: $store.selectedJobID.sending(\.jobSelected)) { job in
                        NavigationLink(value: job.id) {
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
                                
                                let savedLevels = store.state.savedLevels(for: job.id)
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
                }
            case let .failed(message):
                ContentUnavailableView(
                    L10n.SkillRotation.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle(L10n.SkillRotation.title)
        .navigationBarTitleDisplayMode(.inline)
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
    BattleJobListView()
}
