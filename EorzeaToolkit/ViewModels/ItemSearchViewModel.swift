import Foundation

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
    private(set) var baseEquipSlots: [EquipSlot] = []
    private(set) var restrictedEquipSlots: [EquipSlot] = []
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
    /// A parsed sentence waiting for the screen to finish closing before it is applied.
    private var pendingDescriptionResult: (query: ItemQuery, onlyNamesakeID: Int?)?

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
    /// hands them in: the app passes `ItemDescriptionSearchEngine.live`, tests their own. The
    /// memory defaults to `ItemDescriptionSearchMemory.shared`, read here rather than in a
    /// default argument, which is evaluated outside the main actor.
    init(
        descriptionSearchEngine: ItemDescriptionSearchEngine = .unsupported,
        descriptionSearchMemory: ItemDescriptionSearchMemory? = nil,
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
        self.descriptionSearchMemory = descriptionSearchMemory ?? .shared
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
        (baseEquipSlots, restrictedEquipSlots) = EquipSlot.filterSections(equipSlots)
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
                ItemSearchQuery.searchItems(
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
        pendingDescriptionResult = nil
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
        // A parsed sentence already waiting stays: the screen closing is what applies it.
        abandonDescriptionParse()
        descriptionSearchMessage = nil
        isShowingDescriptionSearch = false
    }

    /// Parses the sentence, then closes the screen, applying the result once it has closed, or
    /// keeps the screen open with a message. Returns the parse for tests to wait on.
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
                        ItemSearchQuery.onlyItemID(named: keyword, in: sourceItems)
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
                if let message = Self.message(for: parsed.query) {
                    descriptionSearchMessage = message
                    return
                }
                // The screen closes first; changing the filter, the search text and the toolbar
                // while it animates away made the animation stutter.
                // `descriptionSearchDidClose()` applies the result once it has gone.
                pendingDescriptionResult = parsed
                isShowingDescriptionSearch = false
            case .failure:
                descriptionSearchMessage = .failed
            }
        }
        descriptionParseTask = task
        return task
    }

    /// Called once the description search screen has finished closing. Applies a parsed
    /// sentence waiting for it, and returns the work that opens a recipe lookup's item, for
    /// tests to wait on.
    @discardableResult
    func descriptionSearchDidClose() -> Task<Void, Never>? {
        guard !isShowingDescriptionSearch, let parsed = pendingDescriptionResult else {
            return nil
        }
        pendingDescriptionResult = nil
        applyDescriptionQuery(parsed.query)

        guard let itemID = parsed.onlyNamesakeID else {
            return nil
        }
        return Task {
            // Opened once its name search has listed it: on a narrow screen the detail page is
            // pushed from the result list, which must be showing.
            await searchTask?.value
            itemIDToOpen = itemID
        }
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

    /// Why a parsed sentence cannot be applied, or nil when it can
    /// (prompts/item-description-search.md, 「描述搜尋畫面」).
    private static func message(for parsedQuery: ItemQuery) -> ItemDescriptionSearchMessage? {
        switch parsedQuery.usage {
        case .unsupported:
            return .notAnItemQuery
        case .recipe:
            return parsedQuery.keyword == nil ? .notAnItemQuery : nil
        case .search:
            return parsedQuery.keyword != nil || parsedQuery.hasConditions ? nil : .nothingFound
        }
    }

    /// Applies a parsed sentence that `message(for:)` let through, replacing the filter and
    /// search text whole (「套用」「查配方」).
    private func applyDescriptionQuery(_ parsedQuery: ItemQuery) {
        switch parsedQuery.usage {
        case .unsupported:
            break
        case .recipe:
            // The name search lists the item; the only item with that name, if there is one,
            // is opened as well.
            applySearch(filter: ItemFilter(), query: parsedQuery.keyword ?? "")
        case .search:
            applySearch(filter: ItemFilter(query: parsedQuery), query: parsedQuery.keyword ?? "")
        }
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
}
