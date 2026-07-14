import SwiftUI

struct ItemSearchView: View {
    @State private var viewModel = ItemSearchViewModel()
    @State private var isShowingFilterSheet = false

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView(L10n.ItemSearch.loadingItems)
            case .loaded:
                loadedContent
            case .failed(let message):
                ContentUnavailableView(
                    L10n.ItemSearch.loadFailedTitle,
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle(L10n.ItemSearch.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateSearchQuery($0) }
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: L10n.ItemSearch.searchPrompt
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
        }
        .sheet(isPresented: $isShowingFilterSheet) {
            ItemFilterSheet(viewModel: viewModel)
        }
        .task {
            viewModel.loadItems()
        }
    }

    private var filterButton: some View {
        Button {
            isShowingFilterSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .frame(width: 30, height: 30)

                if viewModel.filter.isActive {
                    Text("\(viewModel.filter.activeFilterCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(.red, in: Circle())
                        .padding(.top, 1)
                        .padding(.trailing, 1)
                }
            }
            .frame(width: 38, height: 38)
        }
        .accessibilityLabel(Text(L10n.ItemSearch.filterAccessibility))
    }

    private var loadedContent: some View {
        VStack(spacing: 0) {
            if shouldShowFilterBar {
                filterBar
            }

            searchContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var shouldShowFilterBar: Bool {
        viewModel.filter.isActive ||
            !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            viewModel.isSearching
    }

    private var filterBar: some View {
        Button {
            isShowingFilterSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .imageScale(.small)

                if viewModel.filter.isActive {
                    Text(activeFilterBarText)
                        .lineLimit(1)
                } else {
                    Text(L10n.ItemSearch.adjustFilter)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(L10n.ItemSearch.filterAction)
                    .fontWeight(.semibold)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.bar)
    }

    private var activeFilterBarText: String {
        viewModel.filterSummaryParts.joined(separator: " · ")
    }

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView(
                L10n.ItemSearch.emptySearchTitle,
                systemImage: "magnifyingglass",
                description: Text(L10n.ItemSearch.emptySearchDescription)
            )
        } else if viewModel.results.isEmpty {
            if viewModel.isSearching {
                ProgressView(L10n.ItemSearch.searching)
            } else {
                ContentUnavailableView(
                    L10n.ItemSearch.noResultsTitle,
                    systemImage: "shippingbox",
                    description: Text(L10n.ItemSearch.noResultsDescription)
                )
            }
        } else {
            List {
                ForEach(viewModel.results) { item in
                    NavigationLink(destination: ItemDetailView(item: item, itemsByID: viewModel.itemsByID)) {
                        ItemSearchRow(item: item)
                    }
                }

                if viewModel.hiddenResultCount > 0 {
                    Button {
                        viewModel.loadMoreResults()
                    } label: {
                        VStack(spacing: 4) {
                            Text(L10n.ItemSearch.loadMore)
                                .font(.subheadline.weight(.semibold))

                            Text(L10n.ItemSearch.resultsStatus(
                                visibleCount: viewModel.results.count,
                                totalCount: viewModel.totalMatchCount,
                                hiddenCount: viewModel.hiddenResultCount
                            ))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                }
            }
            .overlay(alignment: .topTrailing) {
                if viewModel.isSearching {
                    ProgressView()
                        .controlSize(.small)
                        .padding()
                }
            }
        }
    }
}

private struct ItemFilterSheet: View {
    let viewModel: ItemSearchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilterPage: ItemFilterPage = .general
    @State private var expandedUICategoryGroupIds: Set<Int> = []

    private let rarityColumns = [
        GridItem(.adaptive(minimum: 88), spacing: 8)
    ]
    private let jobColumns = [
        GridItem(.adaptive(minimum: 88), spacing: 8)
    ]
    private let equipSlotColumns = [
        GridItem(.adaptive(minimum: 92), spacing: 8)
    ]

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
                        .pickerStyle(.segmented)
                    }
                }

                switch selectedFilterPage {
                case .general:
                    generalFilterSections
                case .advanced:
                    advancedFilterSections
                }
            }
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
        }
    }

    private var hasAdvancedFilters: Bool {
        !viewModel.uiCategoryGroups.isEmpty ||
            !viewModel.availableJobFilterOptions.isEmpty ||
            !viewModel.equipSlots.isEmpty
    }

    @ViewBuilder
    private var generalFilterSections: some View {
        Section(L10n.ItemSearch.Filter.itemLevel) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(viewModel.filter.ilvlRange.lowerBound)")
                        .font(.headline.monospacedDigit())

                    Spacer()

                    Text("\(viewModel.filter.ilvlRange.upperBound)")
                        .font(.headline.monospacedDigit())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(L10n.ItemSearch.Filter.itemLevelRange(
                    lowerBound: viewModel.filter.ilvlRange.lowerBound,
                    upperBound: viewModel.filter.ilvlRange.upperBound
                )))

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.ItemSearch.Filter.itemLevelMinimum)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: minimumItemLevelBinding,
                        in: Double(ItemFilter.defaultIlvlRange.lowerBound)...Double(viewModel.filter.ilvlRange.upperBound),
                        step: 1
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.ItemSearch.Filter.itemLevelMaximum)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: maximumItemLevelBinding,
                        in: Double(viewModel.filter.ilvlRange.lowerBound)...Double(ItemFilter.defaultIlvlRange.upperBound),
                        step: 1
                    )
                }
            }
            .padding(.vertical, 4)
        }

        Section(L10n.ItemSearch.Filter.rarity) {
            LazyVGrid(columns: rarityColumns, alignment: .leading, spacing: 8) {
                ForEach(ItemFilter.defaultRarities.sorted(), id: \.self) { rarity in
                    rarityButton(for: rarity)
                }
            }
            .padding(.vertical, 4)
        }

        Section(L10n.ItemSearch.Filter.hq) {
            Picker(L10n.ItemSearch.Filter.hq, selection: hqStateBinding) {
                Text(L10n.ItemSearch.Filter.hqAny).tag(ItemBoolFilterState.any)
                Text(L10n.ItemSearch.Filter.hqOnly).tag(ItemBoolFilterState.only)
                Text(L10n.ItemSearch.Filter.hqExclude).tag(ItemBoolFilterState.exclude)
            }
            .pickerStyle(.segmented)
        }

        Section(L10n.ItemSearch.Filter.tradable) {
            Picker(L10n.ItemSearch.Filter.tradable, selection: tradableStateBinding) {
                Text(L10n.ItemSearch.Filter.tradableAny).tag(ItemBoolFilterState.any)
                Text(L10n.ItemSearch.Filter.tradableOnly).tag(ItemBoolFilterState.only)
                Text(L10n.ItemSearch.Filter.tradableExclude).tag(ItemBoolFilterState.exclude)
            }
            .pickerStyle(.segmented)
        }
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
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }

        if !viewModel.availableJobFilterOptions.isEmpty {
            Section(L10n.ItemSearch.Filter.jobs) {
                LazyVGrid(columns: jobColumns, alignment: .leading, spacing: 8) {
                    ForEach(viewModel.availableJobFilterOptions) { option in
                        jobButton(option)
                    }
                }
                .padding(.vertical, 4)
            }
        }

        if !viewModel.equipSlots.isEmpty {
            Section(L10n.ItemSearch.Filter.equipSlot) {
                LazyVGrid(columns: equipSlotColumns, alignment: .leading, spacing: 8) {
                    ForEach(viewModel.equipSlots) { equipSlot in
                        equipSlotButton(equipSlot)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var minimumItemLevelBinding: Binding<Double> {
        Binding {
            Double(viewModel.filter.ilvlRange.lowerBound)
        } set: { newValue in
            viewModel.updateMinimumItemLevel(Int(newValue.rounded()))
        }
    }

    private var maximumItemLevelBinding: Binding<Double> {
        Binding {
            Double(viewModel.filter.ilvlRange.upperBound)
        } set: { newValue in
            viewModel.updateMaximumItemLevel(Int(newValue.rounded()))
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? rarityColor(for: rarity) : .secondary)
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? rarityColor(for: rarity) : .secondary)
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
            return .secondary
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
                    .foregroundStyle(.primary)

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
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

                Text(option.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 62)
        }
        .buttonStyle(.borderedProminent)
        .tint(isSelected ? .accentColor : .secondary.opacity(0.18))
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
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

private struct ItemSearchRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            ItemIconView(item: item, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(L10n.ItemSearch.itemLevel(item.ilvl))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ItemSearchView()
    }
}
