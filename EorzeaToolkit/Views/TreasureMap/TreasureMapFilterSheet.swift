import SwiftUI

struct TreasureMapFilterSheet: View {
    let viewModel: TreasureMapViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.TreasureMap.filterVersionSection) {
                    ForEach(viewModel.versionOptions, id: \.self) { majorVersion in
                        optionButton(
                            L10n.TreasureMap.filterVersionOption(majorVersion),
                            isSelected: viewModel.filter.selectedMajorVersions.contains(majorVersion)
                        ) {
                            viewModel.toggleMajorVersion(majorVersion)
                        }
                    }
                }
                .appThemedListRow()

                Section(L10n.TreasureMap.filterLevelSection) {
                    ForEach(viewModel.levelOptions, id: \.self) { level in
                        optionButton(
                            L10n.TreasureMap.filterLevelOption(level),
                            isSelected: viewModel.filter.selectedLevels.contains(level)
                        ) {
                            viewModel.toggleLevel(level)
                        }
                    }
                }
                .appThemedListRow()
            }
            .appThemedScrollContent()
            .navigationTitle(L10n.TreasureMap.filterTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.TreasureMap.clearAllFilters, action: viewModel.clearFilters)
                        .disabled(!viewModel.isFilterActive)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                }
            }
            .appThemedScreen(tint: HomeFeature.treasureMap.accent)
        }
    }

    private func optionButton(
        _ title: LocalizedStringKey,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(AppTheme.ink)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? HomeFeature.treasureMap.accent : AppTheme.mutedInk)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityValue(Text(isSelected ? L10n.Common.selected : L10n.Common.notSelected))
    }
}
