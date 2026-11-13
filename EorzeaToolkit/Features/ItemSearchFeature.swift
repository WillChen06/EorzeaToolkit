//
//  ItemSearchFeature.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/12.
//

import ComposableArchitecture

@Reducer
struct ItemSearchFeature {
    enum CancelID { case search }
    
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }
    
    @ObservableState
    struct State: Equatable {
        static let pageSize = 50
        
        var loadState: LoadState = .idle
        var catalog: ItemCatalog?
        
        var query = ""
        var filter = ItemFilter()
        var allResults: [Item] = []
        var visibleResultCount = 0
        var isSearching = false
        var isFilterPresented = false
        
        var results: [Item] {
            Array(allResults.prefix(visibleResultCount))
        }
        
        var totalMatchCount: Int {
            allResults.count
        }
        
        var hiddenResultCount: Int {
            max(totalMatchCount - visibleResultCount, 0)
        }

        var canLoadMoreResults: Bool {
            visibleResultCount < totalMatchCount
        }
        
        var isWaitingForSearch: Bool {
            isQueryEmpty && !filter.isActive
        }
        
        var isFilterOnlySearch: Bool {
            isQueryEmpty && filter.isActive
        }
        
        var uiCategoryGroups: [UICategoryGroup] {
            UICategoryGroup.groups(from: catalog?.uiCategories ?? [])
        }

        var availableJobFilterOptions: [ItemJobFilterOption] {
            ItemJobFilterOption.available(in: catalog?.classjobJobSetsById ?? [:])
        }

        var equipSlots: [EquipSlot] {
            catalog?.equipSlots ?? []
        }

        var baseEquipSlots: [EquipSlot] {
            catalog?.baseEquipSlots ?? []
        }

        var restrictedEquipSlots: [EquipSlot] {
            catalog?.restrictedEquipSlots ?? []
        }

        var filterSummaryParts: [String] {
            filter.summaryParts(
                uiCategories: catalog?.uiCategories ?? [],
                equipSlots: equipSlots
            )
        }
        
        private var isQueryEmpty: Bool {
            query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    enum Action {
        case task
        case catalogResponse(Result<ItemCatalog, Error>)
        case refreshResponse(ItemCatalog?)
        case searchQueryChanged(String)
        case searchResponse(ItemSearchResult)
        case loadMoreButtonTapped
        case filterPresentationChanged(Bool)
        case minimumItemLevelChanged(Int)
        case maximumItemLevelChanged(Int)
        case minimumEquipLevelChanged(Int)
        case maximumEquipLevelChanged(Int)
        case rarityToggled(Int)
        case hqStateChanged(ItemBoolFilterState)
        case tradableStateChanged(ItemBoolFilterState)
        case uiCategoryToggled(Int)
        case jobToggled(String)
        case equipSlotToggled(Int)
        case clearFilterButtonTapped
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.itemData) var itemData
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                switch state.loadState {
                case .loading, .loaded:
                    return .none
                case .idle, .failed:
                    break
                }
                state.loadState = .loading
                return .run { send in
                    await send(.catalogResponse(Result {
                        try await itemData.load()
                    }))
                }
            case let .catalogResponse(.success(catalog)):
                state.loadState = .loaded
                state.catalog = catalog
                return .merge(
                    search(&state, debounce: false),
                    .run { send in
                        let refreshed = try? await itemData.refresh(currentVersion: catalog.version)
                        await send(.refreshResponse(refreshed))
                    }
                )
            case let .catalogResponse(.failure(error)):
                state.loadState = .failed(error.localizedDescription)
                state.catalog = nil
                state.allResults.removeAll()
                state.visibleResultCount = 0
                state.isSearching = false
                return .none
            case let .refreshResponse(catalog):
                guard let catalog else { return .none }
                state.catalog = catalog
                return search(&state, debounce: false)
            case let .searchQueryChanged(query):
                state.query = query
                return search(&state, debounce: true)
            case let .searchResponse(result):
                state.allResults = result.items
                state.visibleResultCount = min(State.pageSize, result.items.count)
                state.isSearching = false
                return .none
            case .loadMoreButtonTapped:
                guard state.canLoadMoreResults else { return .none }
                state.visibleResultCount = min(
                    state.visibleResultCount + State.pageSize,
                    state.allResults.count
                )
                return .none
            case let .filterPresentationChanged(isPresented):
                state.isFilterPresented = isPresented
                return .none
            case let .minimumItemLevelChanged(level):
                return updateFilter(&state) { $0.setMinimumItemLevel(level) }
            case let .maximumItemLevelChanged(level):
                return updateFilter(&state) { $0.setMaximumItemLevel(level) }
            case let .minimumEquipLevelChanged(level):
                return updateFilter(&state) { $0.setMinimumEquipLevel(level) }
            case let .maximumEquipLevelChanged(level):
                return updateFilter(&state) { $0.setMaximumEquipLevel(level) }
            case let .rarityToggled(rarity):
                return updateFilter(&state) {
                    $0.selectedRarities.formSymmetricDifference([rarity])
                }
            case let .hqStateChanged(hqState):
                return updateFilter(&state) { $0.hqState = hqState }
            case let .tradableStateChanged(tradableState):
                return updateFilter(&state) { $0.tradableState = tradableState }
            case let .uiCategoryToggled(categoryID):
                return updateFilter(&state) {
                    $0.selectedUICategoryIds.formSymmetricDifference([categoryID])
                }
            case let .jobToggled(abbreviation):
                return updateFilter(&state) {
                    $0.selectedJobAbbrs.formSymmetricDifference([abbreviation])
                }
            case let .equipSlotToggled(equipSlotID):
                return updateFilter(&state) {
                    $0.selectedEquipSlots.formSymmetricDifference([equipSlotID])
                }
            case .clearFilterButtonTapped:
                return updateFilter(&state, debounce: false) { $0 = ItemFilter() }
            }
        }
    }
    
    private func search(_ state: inout State, debounce: Bool) -> Effect<Action> {
        let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // With an empty search field, an active filter alone lists its items. With neither,
        // nothing is listed, and a search still waiting must not list anything later.
        guard !query.isEmpty || state.filter.isActive else {
            state.allResults = []
            state.visibleResultCount = 0
            state.isSearching = false
            return .cancel(id: CancelID.search)
        }
        
        // The items have not loaded yet; loading them searches the text then.
        guard let catalog = state.catalog else {
            state.allResults = []
            state.visibleResultCount = 0
            state.isSearching = false
            return .cancel(id: CancelID.search)
        }
        
        state.isSearching = true
        let filter = state.filter
        return .run { send in
            if debounce {
                try await clock.sleep(for: .milliseconds(300))
            }
            let result = ItemSearchQuery.searchItems(
                catalog.items,
                query: query,
                filter: filter,
                classjobJobSetsById: catalog.classjobJobSetsById
            )
            await send(.searchResponse(result))
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }
    
    private func updateFilter(
        _ state: inout State,
        debounce: Bool = true,
        _ mutation: (inout ItemFilter) -> Void
    ) -> Effect<Action> {
        var filter = state.filter
        mutation(&filter)
        guard filter != state.filter else { return .none }
        state.filter = filter
        return search(&state, debounce: debounce)
    }
}

