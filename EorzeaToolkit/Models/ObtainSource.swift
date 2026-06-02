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
            return "製作"
        case .gathering:
            return "採集"
        case .shop:
            return "商店購買"
        case .market:
            return "市場交易"
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
