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

    var isActive: Bool {
        ilvlRange != Self.defaultIlvlRange ||
            selectedRarities != Self.defaultRarities ||
            hqState != .any ||
            tradableState != .any
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

        return count
    }

    var summaryParts: [String] {
        var parts: [String] = []

        if ilvlRange != Self.defaultIlvlRange {
            parts.append("品級 \(ilvlRange.lowerBound)-\(ilvlRange.upperBound)")
        }

        if selectedRarities != Self.defaultRarities {
            if selectedRarities.isEmpty {
                parts.append("無稀有度")
            } else {
                let names = selectedRarities
                    .sorted()
                    .compactMap { Self.rarityName(for: $0) }
                    .joined(separator: "、")
                parts.append("稀有度 \(names)")
            }
        }

        switch hqState {
        case .any:
            break
        case .only:
            parts.append("可HQ")
        case .exclude:
            parts.append("不可HQ")
        }

        switch tradableState {
        case .any:
            break
        case .only:
            parts.append("可交易")
        case .exclude:
            parts.append("不可交易")
        }

        return parts
    }

    static func rarityName(for rarity: Int) -> String? {
        switch rarity {
        case 1:
            return "一般"
        case 2:
            return "稀有"
        case 3:
            return "貴重"
        case 4:
            return "武勳"
        case 7:
            return "紅蓮"
        default:
            return nil
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

    var query = ""

    private var items: [Item] = []
    private var allSearchResults: [Item] = []
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

    func loadItems() {
        guard loadState != .loading, loadState != .loaded else {
            return
        }

        loadTask?.cancel()
        loadState = .loading

        loadTask = Task {
            do {
                let loadedItems = try await ItemDataService.loadCachedOrBundledItems()

                guard !Task.isCancelled else {
                    return
                }

                items = loadedItems
                loadState = .loaded
                runSearch(for: query, debounce: false)
                await refreshRemoteItemsIfNeeded()
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                items = []
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
        let delay = searchDebounceNanoseconds

        searchTask = Task {
            if debounce {
                try? await Task.sleep(nanoseconds: delay)
            }

            guard !Task.isCancelled else {
                return
            }

            let searchResult = await Task.detached(priority: .userInitiated) {
                Self.searchItems(sourceItems, query: trimmedQuery, filter: activeFilter)
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
            guard let refreshedItems = try await ItemDataService.refreshItemsIfNeeded() else {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            items = refreshedItems
            runSearch(for: query, debounce: false)
        } catch {
            guard !Task.isCancelled else {
                return
            }
        }
    }

    nonisolated private static func searchItems(_ items: [Item], query: String, filter: ItemFilter) -> ItemSearchResult {
        let normalizedQuery = normalize(query)
        var matches: [ItemSearchMatch] = []

        for item in items {
            guard matchesFilter(item, filter: filter) else {
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

    nonisolated private static func matchesFilter(_ item: Item, filter: ItemFilter) -> Bool {
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

        return true
    }

    nonisolated private static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

private struct ItemSearchMatch: Sendable {
    let item: Item
    let rank: Int
}

private struct ItemSearchResult: Sendable {
    let items: [Item]
    let totalCount: Int
}
