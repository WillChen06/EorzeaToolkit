import SwiftUI

struct RelicWeaponListView: View {
    @State private var viewModel = RelicWeaponViewModel()

    var body: some View {
        List {
            ForEach(viewModel.expansions) { expansion in
                Section(expansion.name) {
                    ForEach(expansion.weapons) { weapon in
                        NavigationLink(destination: RelicWeaponDetailView(weapon: weapon)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(weapon.name)
                                    .font(.headline)
                                Text("\(weapon.job) · \(weapon.steps.count) 個步驟")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("發光武器")
        .task {
            viewModel.loadWeapons()
        }
    }
}

#Preview {
    NavigationStack {
        RelicWeaponListView()
    }
}
