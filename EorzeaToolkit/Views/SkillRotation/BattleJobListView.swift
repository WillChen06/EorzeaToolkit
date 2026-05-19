import SwiftUI

struct BattleJobListView: View {
    @State private var viewModel = SkillRotationViewModel()

    var body: some View {
        List(viewModel.jobs) { job in
            NavigationLink {
                SkillRotationEditorView(job: job, viewModel: viewModel)
            } label: {
                HStack(spacing: 14) {
                    CachedIconImage(url: job.iconURL) {
                        placeholder
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("技能循環")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
    }
}

#Preview {
    NavigationStack {
        BattleJobListView()
    }
}
