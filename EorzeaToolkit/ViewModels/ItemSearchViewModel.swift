import Foundation

enum ItemBoolFilterState: String, CaseIterable, Sendable {
    case any
    case only
    case exclude
}

struct ItemFilter: Equatable, Sendable {
    static let defaultIlvlRange = 1...795
    static let defaultRarities: Set<Int> = [1, 2, 3, 4, 7]

    var ilvlRange: ClosedRange<Int> = Self.defaultIlvlRange
    var selectedRarities: Set<Int> = Self.defaultRarities
    var hqState: ItemBoolFilterState = .any
    var tradableState: ItemBoolFilterState = .any
    var selectedUICategoryIds: Set<Int> = []
    var selectedJobAbbrs: Set<String> = []
    var selectedEquipSlots: Set<Int> = []

    var isActive: Bool {
        ilvlRange != Self.defaultIlvlRange ||
            selectedRarities != Self.defaultRarities ||
            hqState != .any ||
            tradableState != .any ||
            !selectedUICategoryIds.isEmpty ||
            !selectedJobAbbrs.isEmpty ||
            !selectedEquipSlots.isEmpty
    }

    var activeFilterCount: Int {
        var count = 0

        if ilvlRange != Self.defaultIlvlRange {
            count += 1
        }

        if selectedRarities != Self.defaultRarities {
            count += 1
        }

        if hqState != .any {
            count += 1
        }

        if tradableState != .any {
            count += 1
        }

        if !selectedUICategoryIds.isEmpty {
            count += 1
        }

        if !selectedJobAbbrs.isEmpty {
            count += 1
        }

        if !selectedEquipSlots.isEmpty {
            count += 1
        }

        return count
    }

    var summaryParts: [String] {
        var parts: [String] = []

        if ilvlRange != Self.defaultIlvlRange {
            parts.append(L10n.ItemSearch.Filter.summaryItemLevel(
                lowerBound: ilvlRange.lowerBound,
                upperBound: ilvlRange.upperBound
            ))
        }

        if selectedRarities != Self.defaultRarities {
            if selectedRarities.isEmpty {
                parts.append(L10n.ItemSearch.Filter.noRaritySummaryText)
            } else {
                let names = selectedRarities
                    .sorted()
                    .compactMap { Self.rarityName(for: $0) }
                    .joined(separator: L10n.ItemSearch.Filter.summaryListSeparator)
                parts.append(L10n.ItemSearch.Filter.raritySummary(names))
            }
        }

        switch hqState {
        case .any:
            break
        case .only:
            parts.append(L10n.ItemSearch.Filter.hqOnlySummaryText)
        case .exclude:
            parts.append(L10n.ItemSearch.Filter.hqExcludeSummaryText)
        }

        switch tradableState {
        case .any:
            break
        case .only:
            parts.append(L10n.ItemSearch.Filter.tradableOnlySummaryText)
        case .exclude:
            parts.append(L10n.ItemSearch.Filter.tradableExcludeSummaryText)
        }

        return parts
    }

    func summaryParts(
        uiCategoryNamesById: [Int: String],
        jobNamesByAbbr: [String: String],
        equipSlotNamesById: [Int: String]
    ) -> [String] {
        var parts = summaryParts

        appendSelectionSummary(
            from: selectedUICategoryIds,
            lookup: uiCategoryNamesById,
            fallbackName: { L10n.ItemSearch.Filter.categoryFallbackName(id: $0) },
            countSummary: L10n.ItemSearch.Filter.categorySelectionCount(_:),
            to: &parts
        )
        appendSelectionSummary(
            from: selectedEquipSlots,
            lookup: equipSlotNamesById,
            fallbackName: { L10n.ItemSearch.Filter.equipSlotFallbackName(id: $0) },
            countSummary: L10n.ItemSearch.Filter.equipSlotSelectionCount(_:),
            to: &parts
        )
        appendSelectionSummary(
            from: selectedJobAbbrs,
            lookup: jobNamesByAbbr,
            fallbackName: L10n.ItemSearch.Filter.jobFallbackName(abbreviation:),
            countSummary: L10n.ItemSearch.Filter.jobSelectionCount(_:),
            to: &parts
        )

        if parts.count > 3 {
            return [L10n.ItemSearch.Filter.activeFilterSummary(count: activeFilterCount)]
        }

        return parts
    }

    static func rarityName(for rarity: Int) -> String? {
        L10n.ItemSearch.Filter.rarityName(rarity)
    }

    private func appendSelectionSummary<T: Comparable>(
        from selection: Set<T>,
        lookup: [T: String],
        fallbackName: (T) -> String,
        countSummary: (Int) -> String,
        to parts: inout [String]
    ) {
        guard !selection.isEmpty else {
            return
        }

        let names = selection
            .sorted()
            .map { lookup[$0] ?? fallbackName($0) }

        if names.count <= 2 {
            parts.append(contentsOf: names)
        } else {
            parts.append(countSummary(names.count))
        }
    }
}

@MainActor
@Observable
final class ItemSearchViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var results: [Item] = []
    private(set) var totalMatchCount = 0
    private(set) var isSearching = false
    private(set) var filter = ItemFilter()
    private(set) var uiCategories: [UICategory] = []
    private(set) var classjobCategories: [ClassJobCategory] = []
    private(set) var equipSlots: [EquipSlot] = []
    private(set) var itemsByID: [Int: Item] = [:]

    var query = ""

    private var items: [Item] = []
    private var allSearchResults: [Item] = []
    private var classjobJobSetsById: [Int: Set<String>] = [:]
    private var loadTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    private let pageSize = 50
    private let searchDebounceNanoseconds: UInt64 = 300_000_000

    var hiddenResultCount: Int {
        max(totalMatchCount - results.count, 0)
    }

    var canLoadMoreResults: Bool {
        results.count < totalMatchCount
    }

    var hasLoadedItems: Bool {
        loadState == .loaded
    }

    var uiCategoryGroups: [UICategoryGroup] {
        let grouped = Dictionary(grouping: uiCategories) { $0.orderMajor }

        return grouped.keys.sorted().map { orderMajor in
            UICategoryGroup(
                orderMajor: orderMajor,
                title: L10n.ItemSearch.Filter.categoryGroupTitle(orderMajor: orderMajor),
                categories: grouped[orderMajor, default: []].sorted {
                    if $0.orderMinor != $1.orderMinor {
                        return $0.orderMinor < $1.orderMinor
                    }

                    return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
                }
            )
        }
    }

    var availableJobFilterOptions: [ItemJobFilterOption] {
        let supportedAbbrs = Set(classjobJobSetsById.values.flatMap(\.self))
        guard !supportedAbbrs.isEmpty else {
            return []
        }

        return ItemJobFilterOption.displayOptions.filter { supportedAbbrs.contains($0.abbreviation) }
    }

    var filterSummaryParts: [String] {
        filter.summaryParts(
            uiCategoryNamesById: Dictionary(uniqueKeysWithValues: uiCategories.map { ($0.id, $0.displayName) }),
            jobNamesByAbbr: Dictionary(uniqueKeysWithValues: ItemJobFilterOption.displayOptions.map { ($0.abbreviation, $0.displayName) }),
            equipSlotNamesById: Dictionary(uniqueKeysWithValues: equipSlots.map { ($0.id, $0.displayName) })
        )
    }

    func loadItems() {
        guard loadState != .loading, loadState != .loaded else {
            return
        }

        loadTask?.cancel()
        loadState = .loading

        loadTask = Task {
            do {
                let loadedData = try await ItemDataService.loadCachedOrBundledData()

                guard !Task.isCancelled else {
                    return
                }

                applyLoadedData(loadedData)
                loadState = .loaded
                runSearch(for: query, debounce: false)
                await refreshRemoteItemsIfNeeded()
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                items = []
                itemsByID = [:]
                allSearchResults = []
                results = []
                totalMatchCount = 0
                isSearching = false
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    func updateSearchQuery(_ newValue: String) {
        query = newValue
        runSearch(for: newValue, debounce: true)
    }

    func resetFilter() {
        updateFilter(ItemFilter(), debounce: false)
    }

    func updateMinimumItemLevel(_ value: Int) {
        let clampedValue = min(max(value, ItemFilter.defaultIlvlRange.lowerBound), filter.ilvlRange.upperBound)
        updateFilter {
            $0.ilvlRange = clampedValue...$0.ilvlRange.upperBound
        }
    }

    func updateMaximumItemLevel(_ value: Int) {
        let clampedValue = max(min(value, ItemFilter.defaultIlvlRange.upperBound), filter.ilvlRange.lowerBound)
        updateFilter {
            $0.ilvlRange = $0.ilvlRange.lowerBound...clampedValue
        }
    }

    func toggleRarity(_ rarity: Int) {
        updateFilter {
            if $0.selectedRarities.contains(rarity) {
                $0.selectedRarities.remove(rarity)
            } else {
                $0.selectedRarities.insert(rarity)
            }
        }
    }

    func updateHQState(_ state: ItemBoolFilterState) {
        updateFilter {
            $0.hqState = state
        }
    }

    func updateTradableState(_ state: ItemBoolFilterState) {
        updateFilter {
            $0.tradableState = state
        }
    }

    func toggleUICategory(_ categoryId: Int) {
        updateFilter {
            if $0.selectedUICategoryIds.contains(categoryId) {
                $0.selectedUICategoryIds.remove(categoryId)
            } else {
                $0.selectedUICategoryIds.insert(categoryId)
            }
        }
    }

    func toggleJob(_ abbreviation: String) {
        updateFilter {
            if $0.selectedJobAbbrs.contains(abbreviation) {
                $0.selectedJobAbbrs.remove(abbreviation)
            } else {
                $0.selectedJobAbbrs.insert(abbreviation)
            }
        }
    }

    func toggleEquipSlot(_ equipSlotId: Int) {
        updateFilter {
            if $0.selectedEquipSlots.contains(equipSlotId) {
                $0.selectedEquipSlots.remove(equipSlotId)
            } else {
                $0.selectedEquipSlots.insert(equipSlotId)
            }
        }
    }

    private func applyLoadedData(_ data: ItemDataResponse) {
        items = data.items
        itemsByID = Dictionary(uniqueKeysWithValues: data.items.map { ($0.id, $0) })
        uiCategories = data.uiCategories
        classjobCategories = data.classjobCategories
        equipSlots = data.equipSlots.filter { $0.id > 0 }
        classjobJobSetsById = Dictionary(
            uniqueKeysWithValues: data.classjobCategories.map { ($0.id, Set($0.jobs)) }
        )
    }

    private func updateFilter(_ newFilter: ItemFilter, debounce: Bool = true) {
        guard filter != newFilter else {
            return
        }

        filter = newFilter
        runSearch(for: query, debounce: debounce)
    }

    private func updateFilter(debounce: Bool = true, _ mutation: (inout ItemFilter) -> Void) {
        var newFilter = filter
        mutation(&newFilter)
        updateFilter(newFilter, debounce: debounce)
    }

    private func runSearch(for rawQuery: String, debounce: Bool) {
        searchTask?.cancel()

        let trimmedQuery = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            allSearchResults = []
            results = []
            totalMatchCount = 0
            isSearching = false
            return
        }

        guard hasLoadedItems else {
            allSearchResults = []
            results = []
            totalMatchCount = 0
            return
        }

        isSearching = true
        let sourceItems = items
        let activeFilter = filter
        let activeClassjobJobSetsById = classjobJobSetsById
        let delay = searchDebounceNanoseconds

        searchTask = Task {
            if debounce {
                try? await Task.sleep(nanoseconds: delay)
            }

            guard !Task.isCancelled else {
                return
            }

            let searchResult = await Task.detached(priority: .userInitiated) {
                Self.searchItems(
                    sourceItems,
                    query: trimmedQuery,
                    filter: activeFilter,
                    classjobJobSetsById: activeClassjobJobSetsById
                )
            }.value

            guard !Task.isCancelled else {
                return
            }

            allSearchResults = searchResult.items
            totalMatchCount = searchResult.totalCount
            results = Array(searchResult.items.prefix(pageSize))
            isSearching = false
        }
    }

    func loadMoreResults() {
        guard canLoadMoreResults else {
            return
        }

        let nextResultCount = min(results.count + pageSize, totalMatchCount)
        results = Array(allSearchResults.prefix(nextResultCount))
    }

    private func refreshRemoteItemsIfNeeded() async {
        do {
            guard let refreshedData = try await ItemDataService.refreshDataIfNeeded() else {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            applyLoadedData(refreshedData)
            runSearch(for: query, debounce: false)
        } catch {
            guard !Task.isCancelled else {
                return
            }
        }
    }

    nonisolated private static func searchItems(
        _ items: [Item],
        query: String,
        filter: ItemFilter,
        classjobJobSetsById: [Int: Set<String>]
    ) -> ItemSearchResult {
        let normalizedQuery = normalize(query)
        var matches: [ItemSearchMatch] = []

        for item in items {
            guard matchesFilter(item, filter: filter, classjobJobSetsById: classjobJobSetsById) else {
                continue
            }

            let normalizedNameTw = normalize(item.nameTw)
            let normalizedNameCn = normalize(item.nameCn)

            guard normalizedNameTw.contains(normalizedQuery) || normalizedNameCn.contains(normalizedQuery) else {
                continue
            }

            let rank: Int
            if normalizedNameTw == normalizedQuery || normalizedNameCn == normalizedQuery {
                rank = 0
            } else if normalizedNameTw.hasPrefix(normalizedQuery) || normalizedNameCn.hasPrefix(normalizedQuery) {
                rank = 1
            } else {
                rank = 2
            }

            matches.append(ItemSearchMatch(item: item, rank: rank))
        }

        matches.sort { lhs, rhs in
            if lhs.rank != rhs.rank {
                return lhs.rank < rhs.rank
            }

            if lhs.item.ilvl != rhs.item.ilvl {
                return lhs.item.ilvl > rhs.item.ilvl
            }

            return lhs.item.displayName.localizedStandardCompare(rhs.item.displayName) == .orderedAscending
        }

        return ItemSearchResult(items: matches.map(\.item), totalCount: matches.count)
    }

    nonisolated private static func matchesFilter(
        _ item: Item,
        filter: ItemFilter,
        classjobJobSetsById: [Int: Set<String>]
    ) -> Bool {
        if item.ilvl == 0 {
            guard filter.ilvlRange == ItemFilter.defaultIlvlRange else {
                return false
            }
        } else if !filter.ilvlRange.contains(item.ilvl) {
            return false
        }

        guard filter.selectedRarities.contains(item.rarity) else {
            return false
        }

        switch filter.hqState {
        case .any:
            break
        case .only where !item.canBeHq:
            return false
        case .exclude where item.canBeHq:
            return false
        case .only, .exclude:
            break
        }

        switch filter.tradableState {
        case .any:
            break
        case .only where item.isUntradable:
            return false
        case .exclude where !item.isUntradable:
            return false
        case .only, .exclude:
            break
        }

        if !filter.selectedUICategoryIds.isEmpty,
           !filter.selectedUICategoryIds.contains(item.uiCategoryId) {
            return false
        }

        if !filter.selectedJobAbbrs.isEmpty {
            guard let jobSet = classjobJobSetsById[item.classjobCategoryId],
                  !jobSet.isDisjoint(with: filter.selectedJobAbbrs) else {
                return false
            }
        }

        if !filter.selectedEquipSlots.isEmpty,
           !filter.selectedEquipSlots.contains(item.equipSlot) {
            return false
        }

        return true
    }

    nonisolated private static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

}

struct UICategoryGroup: Identifiable, Sendable {
    let orderMajor: Int
    let title: String
    let categories: [UICategory]

    var id: Int { orderMajor }
}

struct ItemJobFilterOption: Identifiable, Hashable, Sendable {
    let abbreviation: String
    let iconPath: String

    var id: String { abbreviation }

    var displayName: String {
        L10n.ItemSearch.Filter.jobName(abbreviation)
    }

    var iconURL: URL? {
        XIVIconURL.make(from: iconPath)
    }

    static let displayOptions: [ItemJobFilterOption] = [
        ItemJobFilterOption(abbreviation: "PLD", iconPath: "062000/062119_hr1.tex"),
        ItemJobFilterOption(abbreviation: "WAR", iconPath: "062000/062121_hr1.tex"),
        ItemJobFilterOption(abbreviation: "DRK", iconPath: "062000/062132_hr1.tex"),
        ItemJobFilterOption(abbreviation: "GNB", iconPath: "062000/062137_hr1.tex"),
        ItemJobFilterOption(abbreviation: "WHM", iconPath: "062000/062124_hr1.tex"),
        ItemJobFilterOption(abbreviation: "SCH", iconPath: "062000/062128_hr1.tex"),
        ItemJobFilterOption(abbreviation: "AST", iconPath: "062000/062133_hr1.tex"),
        ItemJobFilterOption(abbreviation: "SGE", iconPath: "062000/062140_hr1.tex"),
        ItemJobFilterOption(abbreviation: "MNK", iconPath: "062000/062120_hr1.tex"),
        ItemJobFilterOption(abbreviation: "DRG", iconPath: "062000/062122_hr1.tex"),
        ItemJobFilterOption(abbreviation: "NIN", iconPath: "062000/062130_hr1.tex"),
        ItemJobFilterOption(abbreviation: "SAM", iconPath: "062000/062134_hr1.tex"),
        ItemJobFilterOption(abbreviation: "RPR", iconPath: "062000/062139_hr1.tex"),
        ItemJobFilterOption(abbreviation: "VPR", iconPath: "062000/062141_hr1.tex"),
        ItemJobFilterOption(abbreviation: "BRD", iconPath: "062000/062123_hr1.tex"),
        ItemJobFilterOption(abbreviation: "MCH", iconPath: "062000/062131_hr1.tex"),
        ItemJobFilterOption(abbreviation: "DNC", iconPath: "062000/062138_hr1.tex"),
        ItemJobFilterOption(abbreviation: "BLM", iconPath: "062000/062125_hr1.tex"),
        ItemJobFilterOption(abbreviation: "SMN", iconPath: "062000/062127_hr1.tex"),
        ItemJobFilterOption(abbreviation: "RDM", iconPath: "062000/062135_hr1.tex"),
        ItemJobFilterOption(abbreviation: "PCT", iconPath: "062000/062142_hr1.tex"),
        ItemJobFilterOption(abbreviation: "CRP", iconPath: "062000/062108_hr1.tex"),
        ItemJobFilterOption(abbreviation: "BSM", iconPath: "062000/062109_hr1.tex"),
        ItemJobFilterOption(abbreviation: "ARM", iconPath: "062000/062110_hr1.tex"),
        ItemJobFilterOption(abbreviation: "GSM", iconPath: "062000/062111_hr1.tex"),
        ItemJobFilterOption(abbreviation: "LTW", iconPath: "062000/062112_hr1.tex"),
        ItemJobFilterOption(abbreviation: "WVR", iconPath: "062000/062113_hr1.tex"),
        ItemJobFilterOption(abbreviation: "ALC", iconPath: "062000/062114_hr1.tex"),
        ItemJobFilterOption(abbreviation: "CUL", iconPath: "062000/062115_hr1.tex"),
        ItemJobFilterOption(abbreviation: "MIN", iconPath: "062000/062116_hr1.tex"),
        ItemJobFilterOption(abbreviation: "BTN", iconPath: "062000/062117_hr1.tex"),
        ItemJobFilterOption(abbreviation: "FSH", iconPath: "062000/062118_hr1.tex")
    ]
}

private struct ItemSearchMatch: Sendable {
    let item: Item
    let rank: Int
}

private struct ItemSearchResult: Sendable {
    let items: [Item]
    let totalCount: Int
}
