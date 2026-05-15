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
        let delay = searchDebounceNanoseconds

        searchTask = Task {
            if debounce {
                try? await Task.sleep(nanoseconds: delay)
            }

            guard !Task.isCancelled else {
                return
            }

            let searchResult = await Task.detached(priority: .userInitiated) {
                Self.searchItems(sourceItems, query: trimmedQuery)
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

    nonisolated private static func searchItems(_ items: [Item], query: String) -> ItemSearchResult {
        let normalizedQuery = normalize(query)
        var matches: [ItemSearchMatch] = []

        for item in items {
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
