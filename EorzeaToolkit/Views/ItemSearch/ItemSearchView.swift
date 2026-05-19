import SwiftUI

struct ItemSearchView: View {
    @State private var viewModel = ItemSearchViewModel()
    @State private var isShowingFilterSheet = false

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView("載入道具資料")
            case .loaded:
                loadedContent
            case .failed(let message):
                ContentUnavailableView(
                    "無法載入道具資料",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("道具搜尋")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateSearchQuery($0) }
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "輸入道具名稱..."
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
        .accessibilityLabel("篩選")
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

                Text(filterBarText)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("篩選")
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

    private var filterBarText: String {
        if viewModel.filter.isActive {
            return viewModel.filterSummaryParts.joined(separator: " · ")
        }

        return "調整搜尋篩選"
    }

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView(
                "搜尋道具",
                systemImage: "magnifyingglass",
                description: Text("輸入道具名稱開始搜尋")
            )
        } else if viewModel.results.isEmpty {
            if viewModel.isSearching {
                ProgressView("搜尋中")
            } else {
                ContentUnavailableView(
                    "找不到道具",
                    systemImage: "shippingbox",
                    description: Text("請試著輸入其他名稱")
                )
            }
        } else {
            List {
                ForEach(viewModel.results) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemSearchRow(item: item)
                    }
                }

                if viewModel.hiddenResultCount > 0 {
                    Button {
                        viewModel.loadMoreResults()
                    } label: {
                        VStack(spacing: 4) {
                            Text("載入更多")
                                .font(.subheadline.weight(.semibold))

                            Text("已顯示 \(viewModel.results.count) / \(viewModel.totalMatchCount) 筆，還有 \(viewModel.hiddenResultCount) 筆")
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
                        Picker("篩選類型", selection: $selectedFilterPage) {
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
            .navigationTitle("篩選")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("清除") {
                        viewModel.resetFilter()
                    }
                    .disabled(!viewModel.filter.isActive)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
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
        Section("品級 (iLv)") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(viewModel.filter.ilvlRange.lowerBound)")
                        .font(.headline.monospacedDigit())

                    Spacer()

                    Text("\(viewModel.filter.ilvlRange.upperBound)")
                        .font(.headline.monospacedDigit())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("品級範圍 \(viewModel.filter.ilvlRange.lowerBound) 到 \(viewModel.filter.ilvlRange.upperBound)")

                VStack(alignment: .leading, spacing: 6) {
                    Text("最低")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: minimumItemLevelBinding,
                        in: Double(ItemFilter.defaultIlvlRange.lowerBound)...Double(viewModel.filter.ilvlRange.upperBound),
                        step: 1
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("最高")
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

        Section("稀有度") {
            LazyVGrid(columns: rarityColumns, alignment: .leading, spacing: 8) {
                ForEach(ItemFilter.defaultRarities.sorted(), id: \.self) { rarity in
                    rarityButton(for: rarity)
                }
            }
            .padding(.vertical, 4)
        }

        Section("可否 HQ") {
            Picker("可否 HQ", selection: hqStateBinding) {
                Text("不限").tag(ItemBoolFilterState.any)
                Text("可HQ").tag(ItemBoolFilterState.only)
                Text("不可HQ").tag(ItemBoolFilterState.exclude)
            }
            .pickerStyle(.segmented)
        }

        Section("是否可交易") {
            Picker("是否可交易", selection: tradableStateBinding) {
                Text("不限").tag(ItemBoolFilterState.any)
                Text("可交易").tag(ItemBoolFilterState.only)
                Text("不可交易").tag(ItemBoolFilterState.exclude)
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var advancedFilterSections: some View {
        if !viewModel.uiCategoryGroups.isEmpty {
            Section("物品分類") {
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
            Section("可裝備職業") {
                LazyVGrid(columns: jobColumns, alignment: .leading, spacing: 8) {
                    ForEach(viewModel.availableJobFilterOptions) { option in
                        jobButton(option)
                    }
                }
                .padding(.vertical, 4)
            }
        }

        if !viewModel.equipSlots.isEmpty {
            Section("裝備部位") {
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
        .accessibilityLabel("\(name)稀有度")
        .accessibilityValue(isSelected ? "已選取" : "未選取")
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
        .accessibilityValue(isSelected ? "已選取" : "未選取")
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
        .accessibilityValue(isSelected ? "已選取" : "未選取")
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
        .accessibilityValue(isSelected ? "已選取" : "未選取")
    }
}

private enum ItemFilterPage: String, CaseIterable, Identifiable {
    case general
    case advanced

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general:
            return "一般"
        case .advanced:
            return "進階"
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

                Text("iLv \(item.ilvl)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ItemDetailView: View {
    let item: Item

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    ItemIconView(item: item, size: 96)

                    VStack(spacing: 6) {
                        Text(item.displayName)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text("iLv \(item.ilvl)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section("後續擴充") {
                Label("取得方式、配方、採集與市場價格將在後續 Phase 補上", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ItemIconView: View {
    let item: Item
    let size: CGFloat

    var body: some View {
        CachedIconImage(url: item.iconURL) {
            placeholder
        }
        .padding(size * 0.08)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.12))

            Image(systemName: "shippingbox.fill")
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(.blue)
        }
    }
}

#Preview {
    NavigationStack {
        ItemSearchView()
    }
}
