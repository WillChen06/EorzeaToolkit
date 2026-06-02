import Foundation

enum ObtainSource: String, CaseIterable, Identifiable, Sendable {
    case recipe
    case gathering
    case shop
    case market

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recipe:
            return String(localized: "obtain.source.recipe")
        case .gathering:
            return String(localized: "obtain.source.gathering")
        case .shop:
            return String(localized: "obtain.source.shop")
        case .market:
            return String(localized: "obtain.source.market")
        }
    }

    var systemImage: String {
        switch self {
        case .recipe:
            return "hammer"
        case .gathering:
            return "figure.outdoor.cycle"
        case .shop:
            return "storefront"
        case .market:
            return "dollarsign.circle"
        }
    }
}
