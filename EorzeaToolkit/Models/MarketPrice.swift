import Foundation

enum MarketPriceScope: String, CaseIterable, Identifiable, Sendable {
    case chocobo
    case ifrit
    case garuda
    case leviathan
    case phoenix
    case odin
    case bahamut
    case ramuh
    case titan

    var id: String { rawValue }

    var apiName: String {
        switch self {
        case .chocobo:
            return "陸行鳥"
        case .ifrit:
            return "伊弗利特"
        case .garuda:
            return "迦樓羅"
        case .leviathan:
            return "利維坦"
        case .phoenix:
            return "鳳凰"
        case .odin:
            return "奧汀"
        case .bahamut:
            return "巴哈姆特"
        case .ramuh:
            return "拉姆"
        case .titan:
            return "泰坦"
        }
    }

    var displayName: String {
        apiName
    }

    var displayLabel: String {
        switch self {
        case .chocobo:
            return "DC 陸行鳥"
        default:
            return displayName
        }
    }
}

struct MarketPriceData: Equatable, Sendable {
    let itemID: Int
    let scope: MarketPriceScope
    let lastUploadDate: Date?
    let lowestPriceNQ: Int?
    let lowestPriceHQ: Int?
    let averagePrice: Int?
    let averagePriceNQ: Int?
    let averagePriceHQ: Int?
    let listings: [MarketListing]
    let recentSales: [MarketSale]
    let hasListings: Bool
    let hasRecentHistory: Bool
    let hasData: Bool
}

struct MarketListing: Identifiable, Equatable, Sendable {
    let id: String
    let hq: Bool
    let pricePerUnit: Int
    let quantity: Int
    let total: Int
    let worldName: String?
    let retainerName: String?
    let lastReviewDate: Date?
}

struct MarketSale: Identifiable, Equatable, Sendable {
    let id: String
    let hq: Bool
    let pricePerUnit: Int
    let quantity: Int
    let total: Int
    let worldName: String?
    let saleDate: Date?
}
