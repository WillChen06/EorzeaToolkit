import Foundation

/// The server whose market prices item details show. It is saved, so the app opens on the
/// player's own server every time.
@MainActor
@Observable
final class MarketPriceSettings {
    private static let selectedScopeKey = "marketPrice.selectedScope"

    @ObservationIgnored private let defaults: UserDefaults

    var selectedScope: MarketPriceScope {
        didSet {
            defaults.set(selectedScope.rawValue, forKey: Self.selectedScopeKey)
        }
    }

    /// A saved server that no longer exists falls back to the default one.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedScope = defaults.string(forKey: Self.selectedScopeKey)
            .flatMap(MarketPriceScope.init(rawValue:)) ?? .chocobo
    }
}
