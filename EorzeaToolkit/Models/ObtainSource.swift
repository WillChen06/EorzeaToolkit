import Foundation

enum ObtainSource: String, CaseIterable, Identifiable, Sendable {
    case recipe
    case gathering
    case shop
    case market

    var id: String { rawValue }

    var title: String {
        L10n.Obtain.sourceTitleText(self)
    }

    var systemImage: String {
        switch self {
        case .recipe:
            return "hammer"
        case .gathering:
            return "leaf"
        case .shop:
            return "storefront"
        case .market:
            return "dollarsign.circle"
        }
    }
}
