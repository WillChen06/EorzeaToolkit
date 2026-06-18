import Foundation

struct ItemShopDataResponse: Decodable, Sendable {
    let shop: [String: ItemShopEntry]
}

struct ItemShopEntry: Decodable, Hashable, Sendable {
    let priceMid: Int?
    let inGilShop: Bool?

    enum CodingKeys: String, CodingKey {
        case priceMid = "price_mid"
        case inGilShop = "in_gil_shop"
    }

    var isShopPurchase: Bool {
        inGilShop == true
    }
}
