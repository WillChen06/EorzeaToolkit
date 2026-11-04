import SwiftUI
import ComposableArchitecture

struct TreasureMapFilterSheet: View {
    let store: StoreOf<TreasureMapFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L10n.TreasureMap.filterTitle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("treasureMap.filter.title")
                }
                .appThemedListRow()

                Section(L10n.TreasureMap.filterVersionSection) {
                    ForEach(store.versionOptions, id: \.self) { majorVersion in
                        optionButton(
                            L10n.TreasureMap.filterVersionOption(majorVersion),
                            isSelected: store.filter.selectedMajorVersions.contains(majorVersion)
                        ) {
                            store.send(.majorVersionToggled(majorVersion))
                        }
                        .accessibilityIdentifier("treasureMap.filter.version.\(majorVersion)")
                    }
                }
                .appThemedListRow()

                Section(L10n.TreasureMap.filterLevelSection) {
                    ForEach(store.levelOptions, id: \.self) { level in
                        optionButton(
                            L10n.TreasureMap.filterLevelOption(level),
                            isSelected: store.filter.selectedLevels.contains(level)
                        ) {
                            store.send(.levelToggled(level))
                        }
                        .accessibilityIdentifier("treasureMap.filter.level.\(level)")
                    }
                }
                .appThemedListRow()
            }
            .appThemedScrollContent()
            .accessibilityIdentifier("treasureMap.filter.form")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.TreasureMap.clearAllFilters) {
                        store.send(.clearFiltersButtonTapped)
                    }
                    .accessibilityIdentifier("treasureMap.filter.clear")
                    .disabled(!store.isFilterActive)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                    .accessibilityIdentifier("treasureMap.filter.done")
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
                    .fixedSize(horizontal: false, vertical: true)

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
