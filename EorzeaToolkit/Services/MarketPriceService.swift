import Foundation

enum MarketPriceService {
    private static let baseURL = URL(string: "https://universalis.app")!

    enum MarketPriceError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "市場價格網址無效"
            case .invalidResponse:
                return "市場價格回應格式無效"
            case .serverError(let statusCode):
                return "Universalis 服務回應錯誤（\(statusCode)）"
            }
        }
    }

    static func fetchMarketPrice(itemID: Int, scope: MarketPriceScope) async throws -> MarketPriceData {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.path = "/api/v2/\(scope.apiName)/\(itemID)"
        components.queryItems = [
            URLQueryItem(name: "listings", value: "10"),
            URLQueryItem(name: "entries", value: "5")
        ]

        guard let url = components.url else {
            throw MarketPriceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MarketPriceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw MarketPriceError.serverError(httpResponse.statusCode)
        }

        let marketResponse = try JSONDecoder().decode(UniversalisMarketResponse.self, from: data)
        return marketResponse.marketPriceData(itemID: itemID, scope: scope)
    }

    static func universalisMarketURL(itemID: Int) -> URL {
        baseURL.appending(path: "market").appending(path: String(itemID))
    }
}

private struct UniversalisMarketResponse: Decodable, Sendable {
    let itemID: Int?
    let lastUploadTime: Double?
    let listings: [UniversalisListing]
    let recentHistory: [UniversalisSale]
    let averagePrice: Double?
    let averagePriceNQ: Double?
    let averagePriceHQ: Double?
    let minPriceNQ: Double?
    let minPriceHQ: Double?
    let hasData: Bool?

    enum CodingKeys: String, CodingKey {
        case itemID
        case lastUploadTime
        case listings
        case recentHistory
        case averagePrice
        case averagePriceNQ
        case averagePriceHQ
        case minPriceNQ
        case minPriceHQ
        case hasData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        itemID = try container.decodeIfPresent(Int.self, forKey: .itemID)
        lastUploadTime = try container.decodeIfPresent(Double.self, forKey: .lastUploadTime)
        listings = try container.decodeIfPresent([UniversalisListing].self, forKey: .listings) ?? []
        recentHistory = try container.decodeIfPresent([UniversalisSale].self, forKey: .recentHistory) ?? []
        averagePrice = try container.decodeIfPresent(Double.self, forKey: .averagePrice)
        averagePriceNQ = try container.decodeIfPresent(Double.self, forKey: .averagePriceNQ)
        averagePriceHQ = try container.decodeIfPresent(Double.self, forKey: .averagePriceHQ)
        minPriceNQ = try container.decodeIfPresent(Double.self, forKey: .minPriceNQ)
        minPriceHQ = try container.decodeIfPresent(Double.self, forKey: .minPriceHQ)
        hasData = try container.decodeIfPresent(Bool.self, forKey: .hasData)
    }

    func marketPriceData(itemID fallbackItemID: Int, scope: MarketPriceScope) -> MarketPriceData {
        let lowestNQ = price(from: minPriceNQ) ?? lowestListingPrice(isHQ: false)
        let lowestHQ = price(from: minPriceHQ) ?? lowestListingPrice(isHQ: true)
        let average = price(from: averagePrice)
        let averageNQValue = price(from: averagePriceNQ)
        let averageHQValue = price(from: averagePriceHQ)
        let marketListings = listings
            .map(\.marketListing)
            .sorted { lhs, rhs in
                if lhs.pricePerUnit != rhs.pricePerUnit {
                    return lhs.pricePerUnit < rhs.pricePerUnit
                }

                return lhs.total < rhs.total
            }
        let marketSales = recentHistory.map(\.marketSale)
        let hasAnyPrice = [lowestNQ, lowestHQ, average, averageNQValue, averageHQValue].contains { $0 != nil }
        let hasMarketData = hasData == true || !marketListings.isEmpty || !marketSales.isEmpty || hasAnyPrice

        return MarketPriceData(
            itemID: itemID ?? fallbackItemID,
            scope: scope,
            lastUploadDate: uploadDate,
            lowestPriceNQ: lowestNQ,
            lowestPriceHQ: lowestHQ,
            averagePrice: average,
            averagePriceNQ: averageNQValue,
            averagePriceHQ: averageHQValue,
            listings: marketListings,
            recentSales: marketSales,
            hasListings: !marketListings.isEmpty,
            hasRecentHistory: !marketSales.isEmpty,
            hasData: hasMarketData
        )
    }

    private var uploadDate: Date? {
        guard let lastUploadTime, lastUploadTime > 0 else {
            return nil
        }

        return Date(timeIntervalSince1970: lastUploadTime / 1000)
    }

    private func lowestListingPrice(isHQ: Bool) -> Int? {
        listings
            .filter { $0.hq == isHQ }
            .map(\.pricePerUnit)
            .min()
    }

    private func price(from value: Double?) -> Int? {
        guard let value, value > 0 else {
            return nil
        }

        return Int(value.rounded())
    }
}

private struct UniversalisListing: Decodable, Sendable {
    let listingID: String?
    let hq: Bool
    let pricePerUnit: Int
    let quantity: Int
    let total: Int?
    let worldName: String?
    let retainerName: String?
    let lastReviewTime: Double?

    var marketListing: MarketListing {
        MarketListing(
            id: listingID ?? "\(worldName ?? "unknown")-\(hq)-\(pricePerUnit)-\(quantity)-\(lastReviewTime ?? 0)",
            hq: hq,
            pricePerUnit: pricePerUnit,
            quantity: quantity,
            total: total ?? pricePerUnit * quantity,
            worldName: worldName,
            retainerName: retainerName,
            lastReviewDate: dateFromSeconds(lastReviewTime)
        )
    }
}

private struct UniversalisSale: Decodable, Sendable {
    let hq: Bool
    let pricePerUnit: Int
    let quantity: Int
    let timestamp: Double?
    let worldName: String?
    let total: Int?

    var marketSale: MarketSale {
        MarketSale(
            id: "\(worldName ?? "unknown")-\(hq)-\(pricePerUnit)-\(quantity)-\(timestamp ?? 0)",
            hq: hq,
            pricePerUnit: pricePerUnit,
            quantity: quantity,
            total: total ?? pricePerUnit * quantity,
            worldName: worldName,
            saleDate: dateFromSeconds(timestamp)
        )
    }
}

private func dateFromSeconds(_ timestamp: Double?) -> Date? {
    guard let timestamp, timestamp > 0 else {
        return nil
    }

    return Date(timeIntervalSince1970: timestamp)
}
