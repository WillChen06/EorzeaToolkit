import Foundation

@MainActor
@Observable
final class MarketPriceSettings {
    var selectedScope: MarketPriceScope = .chocobo
}

@MainActor
@Observable
final class MarketPriceViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case untradable
        case empty
        case loaded(MarketPriceData)
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle

    private var loadTask: Task<Void, Never>?

    func load(item: Item, scope: MarketPriceScope) {
        loadTask?.cancel()

        guard !item.isUntradable else {
            loadState = .untradable
            return
        }

        loadState = .loading
        loadTask = Task {
            do {
                let marketPrice = try await MarketPriceService.fetchMarketPrice(itemID: item.id, scope: scope)

                guard !Task.isCancelled else {
                    return
                }

                loadState = marketPrice.hasData ? .loaded(marketPrice) : .empty
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                loadState = .failed(error.localizedDescription)
            }
        }
    }
}
