import SwiftUI

struct BattleJobListView: View {
    @State private var viewModel = SkillRotationViewModel()

    var body: some View {
        List(viewModel.jobs) { job in
            NavigationLink {
                SkillRotationEditorView(job: job, viewModel: viewModel)
            } label: {
                HStack(spacing: 14) {
                    AsyncImage(url: job.iconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .failure:
                            placeholder
                        default:
                            placeholder
                        }
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

                    let count = viewModel.rotation(for: job.id).count
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.semibold)
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
