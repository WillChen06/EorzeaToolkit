import Foundation

@MainActor
@Observable
final class MarketPriceSettings {
    var selectedScope: MarketPriceScope = .chocobo
}
