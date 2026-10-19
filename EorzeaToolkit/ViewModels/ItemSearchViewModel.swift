import Foundation

enum ItemBoolFilterState: String, CaseIterable, Sendable {
    case any
    case only
    case exclude
}

struct ItemFilter: Equatable, Sendable {
    static let defaultIlvlRange = 1...795
    /// Equip levels run from 1 to the level cap. Raise the upper bound with the cap:
    /// `scripts/validate_data.py` fails when an item's equip level is above it.
    static let defaultEquipLevelRange = 1...100
    static let defaultRarities: Set<Int> = [1, 2, 3, 4, 7]

    var ilvlRange: ClosedRange<Int> = Self.defaultIlvlRange
    /// Narrowing it keeps only equippable items whose equip level is in the range.
    var equipLevelRange: ClosedRange<Int> = Self.defaultEquipLevelRange
    var selectedRarities: Set<Int> = Self.defaultRarities
    var hqState: ItemBoolFilterState = .any
    var tradableState: ItemBoolFilterState = .any
    var selectedUICategoryIds: Set<Int> = []
    var selectedJobAbbrs: Set<String> = []
    var selectedEquipSlots: Set<Int> = []

    var isActive: Bool {
        ilvlRange != Self.defaultIlvlRange ||
            equipLevelRange != Self.defaultEquipLevelRange ||
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

        if equipLevelRange != Self.defaultEquipLevelRange {
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

        if equipLevelRange != Self.defaultEquipLevelRange {
            parts.append(L10n.ItemSearch.Filter.summaryEquipLevel(
                lowerBound: equipLevelRange.lowerBound,
                upperBound: equipLevelRange.upperBound
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

/// What the minimum and maximum sliders of a level range filter can move across.
///
/// Each slider stops at the other end of the range. When that leaves a slider only one value,
/// because the minimum is at the top or the maximum at the bottom, it is disabled and kept one
/// step wide: SwiftUI's stepped `Slider` traps on a range with no width.
struct LevelRangeSliders: Equatable, Sendable {
    let minimumRange: ClosedRange<Int>
    let maximumRange: ClosedRange<Int>
    let isMinimumDisabled: Bool
    let isMaximumDisabled: Bool

    /// `bounds` must span at least two levels, and `range` must lie inside it.
    init(range: ClosedRange<Int>, bounds: ClosedRange<Int>) {
        minimumRange = bounds.lowerBound...max(range.upperBound, bounds.lowerBound + 1)
        maximumRange = min(range.lowerBound, bounds.upperBound - 1)...bounds.upperBound
        isMinimumDisabled = range.upperBound == bounds.lowerBound
        isMaximumDisabled = range.lowerBound == bounds.upperBound
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

    // Description search (prompts/item-description-search.md).
    private(set) var descriptionSearchAvailability: ItemDescriptionSearchAvailability = .unavailable
    private(set) var isShowingDescriptionSearch = false
    /// The sentence being edited on the description search screen.
    var descriptionSentence = ""
    private(set) var isParsingDescription = false
    private(set) var descriptionSearchMessage: ItemDescriptionSearchMessage?
    /// The item a recipe lookup found, for the screen to open; `didOpenItem()` clears it.
    private(set) var itemIDToOpen: Int?
    private var descriptionParser: ItemDescriptionParser?

    private var items: [Item] = []
    private var allSearchResults: [Item] = []
    private var classjobJobSetsById: [Int: Set<String>] = [:]
    private var loadedDataVersion: String?
    private var loadTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var descriptionParserTask: Task<Void, Never>?
    private var descriptionParseTask: Task<Void, Never>?

    private let pageSize = 50
    private let searchDebounceNanoseconds: UInt64 = 300_000_000
    private let loadData: @Sendable () async throws -> ItemDataResponse
    private let refreshData: @Sendable (_ currentVersion: String?) async throws -> ItemDataResponse?
    private let descriptionSearchEngine: ItemDescriptionSearchEngine
    private let descriptionSearchMemory: ItemDescriptionSearchMemory

    /// The data comes from `ItemDataService` and description search is off, unless the caller
    /// hands them in: the app passes `ItemDescriptionSearchEngine.live`, tests their own.
    init(
        descriptionSearchEngine: ItemDescriptionSearchEngine = .unsupported,
        descriptionSearchMemory: ItemDescriptionSearchMemory = .shared,
        loadData: @escaping @Sendable () async throws -> ItemDataResponse = {
            try await ItemDataService.loadCachedOrBundledData()
        },
        refreshData: @escaping @Sendable (_ currentVersion: String?) async throws -> ItemDataResponse? = {
            try await ItemDataService.refreshDataIfNeeded(currentVersion: $0)
        }
    ) {
        self.loadData = loadData
        self.refreshData = refreshData
        self.descriptionSearchEngine = descriptionSearchEngine
        self.descriptionSearchMemory = descriptionSearchMemory
    }

    var hiddenResultCount: Int {
        max(totalMatchCount - results.count, 0)
    }

    var canLoadMoreResults: Bool {
        results.count < totalMatchCount
    }

    var hasLoadedItems: Bool {
        loadState == .loaded
    }

    /// The search field is empty and the filter is at its defaults, so nothing is listed yet.
    var isWaitingForSearch: Bool {
        isQueryEmpty && !filter.isActive
    }

    /// The search field is empty but the filter is active: every item the filter keeps is listed.
    var isFilterOnlySearch: Bool {
        isQueryEmpty && filter.isActive
    }

    private var isQueryEmpty: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                let loadedData = try await loadData()

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

    func updateMinimumEquipLevel(_ value: Int) {
        let clampedValue = min(
            max(value, ItemFilter.defaultEquipLevelRange.lowerBound),
            filter.equipLevelRange.upperBound
        )
        updateFilter {
            $0.equipLevelRange = clampedValue...$0.equipLevelRange.upperBound
        }
    }

    func updateMaximumEquipLevel(_ value: Int) {
        let clampedValue = max(
            min(value, ItemFilter.defaultEquipLevelRange.upperBound),
            filter.equipLevelRange.lowerBound
        )
        updateFilter {
            $0.equipLevelRange = $0.equipLevelRange.lowerBound...clampedValue
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
        loadedDataVersion = data.version
        items = data.items
        itemsByID = Dictionary(uniqueKeysWithValues: data.items.map { ($0.id, $0) })
        uiCategories = data.uiCategories
        classjobCategories = data.classjobCategories
        equipSlots = data.equipSlots.filter { $0.id > 0 }
        classjobJobSetsById = Dictionary(
            uniqueKeysWithValues: data.classjobCategories.map { ($0.id, Set($0.jobs)) }
        )
        rebuildDescriptionParser(from: data)
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
        // With an empty search field, an active filter alone lists its items.
        guard !trimmedQuery.isEmpty || filter.isActive else {
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
            guard let refreshedData = try await refreshData(loadedDataVersion) else {
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

    // MARK: - Description search

    /// Whether the toolbar shows the description search button. While the screen is open the
    /// button stays, even when reopening found description search unavailable, so the screen
    /// can say so; it goes once the screen closes.
    var showsDescriptionSearchButton: Bool {
        isShowingDescriptionSearch || descriptionSearchAvailability.showsButton
    }

    /// The button is disabled until the items have loaded and their vocabulary is built.
    var canOpenDescriptionSearch: Bool {
        hasLoadedItems && descriptionParser != nil
    }

    var canSubmitDescription: Bool {
        descriptionSearchAvailability.canSearch
            && descriptionParser != nil
            && !isParsingDescription
            && !descriptionSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Checks the model again, when the item search screen opens and when the description
    /// search screen does.
    func refreshDescriptionSearchAvailability() {
        descriptionSearchAvailability = descriptionSearchEngine.availability()
    }

    func openDescriptionSearch() {
        guard canOpenDescriptionSearch, !isShowingDescriptionSearch else {
            return
        }

        refreshDescriptionSearchAvailability()
        descriptionSentence = descriptionSearchMemory.lastSubmittedSentence
        descriptionSearchMessage = nil
        isShowingDescriptionSearch = true
        if descriptionSearchAvailability.canSearch {
            descriptionParser?.prewarm()
        }
    }

    /// Closes the screen by 「取消」 or by dismissing it, and abandons a parse in progress:
    /// its result is never applied.
    func closeDescriptionSearch() {
        abandonDescriptionParse()
        descriptionSearchMessage = nil
        isShowingDescriptionSearch = false
    }

    /// Parses the sentence, then applies it and closes the screen, or keeps the screen open
    /// with a message. Returns the parse for tests to wait on.
    @discardableResult
    func submitDescription() -> Task<Void, Never>? {
        guard canSubmitDescription, let parser = descriptionParser else {
            return nil
        }

        let sentence = descriptionSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        descriptionSearchMemory.lastSubmittedSentence = descriptionSentence
        descriptionSearchMessage = nil
        isParsingDescription = true
        let sourceItems = items

        let task = Task {
            let result: Result<(query: ItemQuery, onlyNamesakeID: Int?), Error>
            do {
                let parsedQuery = try await parser.parse(sentence)
                var onlyNamesakeID: Int?
                if parsedQuery.usage == .recipe, let keyword = parsedQuery.keyword {
                    // Comparing every item's name takes a moment; it stays off the main actor.
                    onlyNamesakeID = await Task.detached(priority: .userInitiated) {
                        Self.onlyItemID(named: keyword, in: sourceItems)
                    }.value
                }
                result = .success((parsedQuery, onlyNamesakeID))
            } catch {
                result = .failure(error)
            }

            // Abandoning the parse cancels this task. Its result is dropped here even when the
            // model ignored the cancellation and answered anyway.
            guard !Task.isCancelled else {
                return
            }

            isParsingDescription = false
            switch result {
            case .success(let parsed):
                if let message = applyDescriptionQuery(parsed.query) {
                    descriptionSearchMessage = message
                    return
                }
                isShowingDescriptionSearch = false

                if let itemID = parsed.onlyNamesakeID {
                    // Opened once its name search has listed it: on a narrow screen the detail
                    // page is pushed from the result list, which must be showing.
                    await searchTask?.value
                    itemIDToOpen = itemID
                }
            case .failure:
                descriptionSearchMessage = .failed
            }
        }
        descriptionParseTask = task
        return task
    }

    /// Called once the screen has opened `itemIDToOpen`.
    func didOpenItem() {
        itemIDToOpen = nil
    }

    /// Waits for the vocabulary a parser needs to be built, so tests can check the result.
    func waitUntilDescriptionSearchIsReady() async {
        await descriptionParserTask?.value
    }

    private func abandonDescriptionParse() {
        descriptionParseTask?.cancel()
        descriptionParseTask = nil
        isParsingDescription = false
    }

    /// Applies a parsed sentence, replacing the filter and search text whole, or returns why
    /// it was not applied (prompts/item-description-search.md, 「套用」「查配方」).
    private func applyDescriptionQuery(_ parsedQuery: ItemQuery) -> ItemDescriptionSearchMessage? {
        switch parsedQuery.usage {
        case .unsupported:
            return .notAnItemQuery
        case .recipe:
            guard let keyword = parsedQuery.keyword else {
                return .notAnItemQuery
            }
            // The name search lists the item; the only item with that name, if there is one,
            // is opened as well.
            applySearch(filter: ItemFilter(), query: keyword)
            return nil
        case .search:
            guard parsedQuery.keyword != nil || parsedQuery.hasConditions else {
                return .nothingFound
            }
            applySearch(filter: ItemFilter(query: parsedQuery), query: parsedQuery.keyword ?? "")
            return nil
        }
    }

    /// The one item named `keyword`, compared as the name search compares names; nil when
    /// none or several are.
    nonisolated static func onlyItemID(named keyword: String, in items: [Item]) -> Int? {
        let normalizedKeyword = normalize(keyword)
        var found: Int?
        for item in items where normalize(item.nameTw) == normalizedKeyword {
            guard found == nil else {
                return nil
            }
            found = item.id
        }
        return found
    }

    private func applySearch(filter newFilter: ItemFilter, query newQuery: String) {
        filter = newFilter
        query = newQuery
        runSearch(for: newQuery, debounce: false)
    }

    /// The parser reads the same items as the search, rebuilt when a remote update arrives.
    /// Building the vocabulary walks every item, so it runs off the main actor.
    private func rebuildDescriptionParser(from data: ItemDataResponse) {
        guard descriptionSearchEngine.isSupported else {
            return
        }

        descriptionParserTask?.cancel()
        descriptionParser = nil
        let engine = descriptionSearchEngine
        descriptionParserTask = Task {
            let parser = await Task.detached(priority: .utility) {
                engine.makeParser(ItemQueryVocabulary(data: data))
            }.value

            guard !Task.isCancelled else {
                return
            }
            descriptionParser = parser
        }
    }

    /// Waits for the data to load, including the remote update, so tests can check the result.
    func waitUntilLoaded() async {
        await loadTask?.value
    }

    /// Waits for the search in progress, so tests can check its results.
    func waitUntilSearchFinishes() async {
        await searchTask?.value
    }

    /// Internal rather than private so tests can search without loading the bundled data. An
    /// empty query keeps every item the filter keeps, in the same order as a name search.
    nonisolated static func searchItems(
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

            guard !normalizedQuery.isEmpty else {
                matches.append(ItemSearchMatch(item: item, rank: 0))
                continue
            }

            let normalizedName = normalize(item.nameTw)

            guard normalizedName.contains(normalizedQuery) else {
                continue
            }

            let rank: Int
            if normalizedName == normalizedQuery {
                rank = 0
            } else if normalizedName.hasPrefix(normalizedQuery) {
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

        // Only equipment is compared. Every other item has an equip level too (bait has the
        // level needed to use it), but once the range is narrowed those items drop out.
        if filter.equipLevelRange != ItemFilter.defaultEquipLevelRange {
            guard item.equipSlot != 0, filter.equipLevelRange.contains(item.equipLevel) else {
                return false
            }
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

extension ItemJobFilterOption {
    var displayName: String {
        L10n.ItemSearch.Filter.jobName(abbreviation)
    }
}

private struct ItemSearchMatch: Sendable {
    let item: Item
    let rank: Int
}

struct ItemSearchResult: Sendable {
    let items: [Item]
    let totalCount: Int
}
