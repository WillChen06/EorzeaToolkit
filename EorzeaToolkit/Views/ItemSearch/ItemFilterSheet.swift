import SwiftUI

struct ItemFilterSheet: View {
    let viewModel: ItemSearchViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var minimumOptionWidth: CGFloat = 88
    @ScaledMetric(relativeTo: .subheadline) private var minimumEquipSlotWidth: CGFloat = 92
    @State private var selectedFilterPage: ItemFilterPage = .general
    @State private var expandedUICategoryGroupIds: Set<Int> = []

    private var optionColumns: [GridItem] {
        [GridItem(dynamicTypeSize.isAccessibilitySize ? .flexible() : .adaptive(minimum: minimumOptionWidth), spacing: 8)]
    }

    private var equipSlotColumns: [GridItem] {
        [GridItem(dynamicTypeSize.isAccessibilitySize ? .flexible() : .adaptive(minimum: minimumEquipSlotWidth), spacing: 8)]
    }

    var body: some View {
        NavigationStack {
            Form {
                if hasAdvancedFilters {
                    Section {
                        Picker(L10n.ItemSearch.Filter.type, selection: $selectedFilterPage) {
                            ForEach(ItemFilterPage.allCases) { page in
                                Text(page.label).tag(page)
                            }
                        }
                        .modifier(AccessibleFilterPickerStyle())
                    }
                    .appThemedListRow()
                }

                switch selectedFilterPage {
                case .general:
                    generalFilterSections
                case .advanced:
                    advancedFilterSections
                }
            }
            .appThemedScrollContent()
            .navigationTitle(L10n.ItemSearch.Filter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.clear) {
                        viewModel.resetFilter()
                    }
                    .disabled(!viewModel.filter.isActive)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                }
            }
            .appThemedScreen(tint: HomeFeature.itemSearch.accent)
        }
    }

    private var hasAdvancedFilters: Bool {
        !viewModel.uiCategoryGroups.isEmpty ||
            !viewModel.availableJobFilterOptions.isEmpty ||
            !viewModel.equipSlots.isEmpty
    }

    @ViewBuilder
    private var generalFilterSections: some View {
        LevelRangeFilterSection(
            title: L10n.ItemSearch.Filter.itemLevel,
            minimumLabel: L10n.ItemSearch.Filter.itemLevelMinimum,
            maximumLabel: L10n.ItemSearch.Filter.itemLevelMaximum,
            range: viewModel.filter.ilvlRange,
            bounds: ItemFilter.defaultIlvlRange,
            accessibilityLabel: L10n.ItemSearch.Filter.itemLevelRange(lowerBound:upperBound:),
            updateMinimum: viewModel.updateMinimumItemLevel,
            updateMaximum: viewModel.updateMaximumItemLevel
        )

        LevelRangeFilterSection(
            title: L10n.ItemSearch.Filter.equipLevel,
            minimumLabel: L10n.ItemSearch.Filter.equipLevelMinimum,
            maximumLabel: L10n.ItemSearch.Filter.equipLevelMaximum,
            range: viewModel.filter.equipLevelRange,
            bounds: ItemFilter.defaultEquipLevelRange,
            accessibilityLabel: L10n.ItemSearch.Filter.equipLevelRange(lowerBound:upperBound:),
            updateMinimum: viewModel.updateMinimumEquipLevel,
            updateMaximum: viewModel.updateMaximumEquipLevel
        )

        Section(L10n.ItemSearch.Filter.rarity) {
            LazyVGrid(columns: optionColumns, alignment: .leading, spacing: 8) {
                ForEach(ItemFilter.defaultRarities.sorted(), id: \.self) { rarity in
                    rarityButton(for: rarity)
                }
            }
            .padding(.vertical, 4)
        }
        .appThemedListRow()

        Section(L10n.ItemSearch.Filter.hq) {
            Picker(L10n.ItemSearch.Filter.hq, selection: hqStateBinding) {
                Text(L10n.ItemSearch.Filter.hqAny).tag(ItemBoolFilterState.any)
                Text(L10n.ItemSearch.Filter.hqOnly).tag(ItemBoolFilterState.only)
                Text(L10n.ItemSearch.Filter.hqExclude).tag(ItemBoolFilterState.exclude)
            }
            .modifier(AccessibleFilterPickerStyle())
        }
        .appThemedListRow()

        Section(L10n.ItemSearch.Filter.tradable) {
            Picker(L10n.ItemSearch.Filter.tradable, selection: tradableStateBinding) {
                Text(L10n.ItemSearch.Filter.tradableAny).tag(ItemBoolFilterState.any)
                Text(L10n.ItemSearch.Filter.tradableOnly).tag(ItemBoolFilterState.only)
                Text(L10n.ItemSearch.Filter.tradableExclude).tag(ItemBoolFilterState.exclude)
            }
            .modifier(AccessibleFilterPickerStyle())
        }
        .appThemedListRow()
    }

    @ViewBuilder
    private var advancedFilterSections: some View {
        if !viewModel.uiCategoryGroups.isEmpty {
            Section(L10n.ItemSearch.Filter.category) {
                ForEach(viewModel.uiCategoryGroups) { group in
                    DisclosureGroup(
                        isExpanded: uiCategoryGroupBinding(for: group.id)
                    ) {
                        ForEach(group.categories) { category in
                            uiCategoryButton(category)
                        }
                    } label: {
                        HStack {
                            Text(group.title)

                            Spacer()

                            Text("\(group.categories.count)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                    }
                }
            }
            .appThemedListRow()
        }

        if !viewModel.availableJobFilterOptions.isEmpty {
            Section(L10n.ItemSearch.Filter.jobs) {
                LazyVGrid(columns: optionColumns, alignment: .leading, spacing: 8) {
                    ForEach(viewModel.availableJobFilterOptions) { option in
                        jobButton(option)
                    }
                }
                .padding(.vertical, 4)
            }
            .appThemedListRow()
        }

        if !viewModel.baseEquipSlots.isEmpty {
            Section(L10n.ItemSearch.Filter.equipSlot) {
                LazyVGrid(columns: equipSlotColumns, alignment: .leading, spacing: 8) {
                    ForEach(viewModel.baseEquipSlots) { equipSlot in
                        equipSlotButton(equipSlot)
                    }
                }
                .padding(.vertical, 4)
            }
            .appThemedListRow()
        }

        // The variants' names run long, so each gets a full row with its restriction underneath.
        if !viewModel.restrictedEquipSlots.isEmpty {
            Section(L10n.ItemSearch.Filter.restrictedEquipSlot) {
                ForEach(viewModel.restrictedEquipSlots) { equipSlot in
                    restrictedEquipSlotRow(equipSlot)
                }
            }
            .appThemedListRow()
        }
    }

    private var hqStateBinding: Binding<ItemBoolFilterState> {
        Binding {
            viewModel.filter.hqState
        } set: { newValue in
            viewModel.updateHQState(newValue)
        }
    }

    private var tradableStateBinding: Binding<ItemBoolFilterState> {
        Binding {
            viewModel.filter.tradableState
        } set: { newValue in
            viewModel.updateTradableState(newValue)
        }
    }

    private func uiCategoryGroupBinding(for groupId: Int) -> Binding<Bool> {
        Binding {
            expandedUICategoryGroupIds.contains(groupId)
        } set: { isExpanded in
            if isExpanded {
                expandedUICategoryGroupIds.insert(groupId)
            } else {
                expandedUICategoryGroupIds.remove(groupId)
            }
        }
    }

    private func rarityButton(for rarity: Int) -> some View {
        let isSelected = viewModel.filter.selectedRarities.contains(rarity)
        let name = ItemFilter.rarityName(for: rarity) ?? "\(rarity)"

        return Button {
            viewModel.toggleRarity(rarity)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.small)

                Text(name)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? rarityColor(for: rarity) : AppTheme.mutedInk)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? rarityColor(for: rarity) : AppTheme.mutedInk)
        .accessibilityLabel(Text(L10n.ItemSearch.Filter.rarityAccessibility(name)))
        .accessibilityValue(Text(isSelected ? L10n.Common.selected : L10n.Common.notSelected))
    }

    private func rarityColor(for rarity: Int) -> Color {
        switch rarity {
        case 1:
            return .gray
        case 2:
            return .green
        case 3:
            return .blue
        case 4:
            return .purple
        case 7:
            return .pink
        default:
            return AppTheme.mutedInk
        }
    }

    private func uiCategoryButton(_ category: UICategory) -> some View {
        let isSelected = viewModel.filter.selectedUICategoryIds.contains(category.id)

        return Button {
            viewModel.toggleUICategory(category.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.small)

                Text(category.displayName)
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .font(.subheadline)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.displayName)
        .accessibilityValue(Text(isSelected ? L10n.Common.selected : L10n.Common.notSelected))
    }

    private func jobButton(_ option: ItemJobFilterOption) -> some View {
        let isSelected = viewModel.filter.selectedJobAbbrs.contains(option.abbreviation)

        return Button {
            viewModel.toggleJob(option.abbreviation)
        } label: {
            VStack(spacing: 5) {
                CachedIconImage(url: option.iconURL) {
                    Circle()
                        .fill(.secondary.opacity(0.18))
                        .overlay {
                            Text(option.abbreviation.prefix(1))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

                Text(option.displayName)
                    .font(.caption.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(isSelected ? Color.white : AppTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 62)
        }
        .buttonStyle(.borderedProminent)
        .tint(isSelected ? HomeFeature.itemSearch.accent : AppTheme.mutedInk.opacity(0.18))
        .accessibilityLabel(option.displayName)
        .accessibilityValue(Text(isSelected ? L10n.Common.selected : L10n.Common.notSelected))
    }

    private func equipSlotButton(_ equipSlot: EquipSlot) -> some View {
        let isSelected = viewModel.filter.selectedEquipSlots.contains(equipSlot.id)

        return Button {
            viewModel.toggleEquipSlot(equipSlot.id)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.small)

                Text(equipSlot.displayName)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .tint(isSelected ? HomeFeature.itemSearch.accent : AppTheme.mutedInk)
        .accessibilityLabel(equipSlot.displayName)
        .accessibilityValue(Text(isSelected ? L10n.Common.selected : L10n.Common.notSelected))
    }

    private func restrictedEquipSlotRow(_ equipSlot: EquipSlot) -> some View {
        let isSelected = viewModel.filter.selectedEquipSlots.contains(equipSlot.id)

        return Button {
            viewModel.toggleEquipSlot(equipSlot.id)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.small)
                    .foregroundStyle(isSelected ? HomeFeature.itemSearch.accent : AppTheme.mutedInk)

                VStack(alignment: .leading, spacing: 2) {
                    Text(equipSlot.baseName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)

                    if let restriction = equipSlot.restriction {
                        Text(restriction)
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(equipSlot.displayName)
        .accessibilityValue(Text(isSelected ? L10n.Common.selected : L10n.Common.notSelected))
    }
}

private enum ItemFilterPage: String, CaseIterable, Identifiable {
    case general
    case advanced

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .general:
            return L10n.ItemSearch.Filter.general
        case .advanced:
            return L10n.ItemSearch.Filter.advanced
        }
    }
}

/// A level range's two bounds over a slider for each of them.
private struct LevelRangeFilterSection: View {
    let title: LocalizedStringKey
    let minimumLabel: LocalizedStringKey
    let maximumLabel: LocalizedStringKey
    let range: ClosedRange<Int>
    let bounds: ClosedRange<Int>
    let accessibilityLabel: (Int, Int) -> LocalizedStringKey
    let updateMinimum: @MainActor (Int) -> Void
    let updateMaximum: @MainActor (Int) -> Void

    var body: some View {
        let sliders = LevelRangeSliders(range: range, bounds: bounds)

        Section(title) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(range.lowerBound)")
                        .font(.headline.monospacedDigit())

                    Spacer()

                    Text("\(range.upperBound)")
                        .font(.headline.monospacedDigit())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(accessibilityLabel(range.lowerBound, range.upperBound)))

                slider(
                    label: minimumLabel,
                    value: Binding {
                        Double(range.lowerBound)
                    } set: { newValue in
                        updateMinimum(Int(newValue.rounded()))
                    },
                    in: sliders.minimumRange,
                    isDisabled: sliders.isMinimumDisabled
                )

                slider(
                    label: maximumLabel,
                    value: Binding {
                        Double(range.upperBound)
                    } set: { newValue in
                        updateMaximum(Int(newValue.rounded()))
                    },
                    in: sliders.maximumRange,
                    isDisabled: sliders.isMaximumDisabled
                )
            }
            .padding(.vertical, 4)
        }
        .appThemedListRow()
    }

    private func slider(
        label: LocalizedStringKey,
        value: Binding<Double>,
        in sliderRange: ClosedRange<Int>,
        isDisabled: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)

            Slider(
                value: value,
                in: Double(sliderRange.lowerBound)...Double(sliderRange.upperBound),
                step: 1
            )
            .disabled(isDisabled)
        }
    }
}
