import Foundation
import os

enum ItemShopDataService {
    private static let cache = ItemShopDataCache()

    static func shopEntry(for itemID: Int) async -> ItemShopEntry? {
        await cache.shopEntry(for: itemID)
    }
}

private actor ItemShopDataCache {
    private var entriesByItemID: [String: ItemShopEntry]?
    private var loadTask: Task<[String: ItemShopEntry], Never>?

    func shopEntry(for itemID: Int) async -> ItemShopEntry? {
        let entriesByItemID = await loadEntriesByItemID()
        return entriesByItemID[String(itemID)]
    }

    private func loadEntriesByItemID() async -> [String: ItemShopEntry] {
        if let entriesByItemID {
            return entriesByItemID
        }

        if let loadTask {
            return await loadTask.value
        }

        let task = Task.detached(priority: .userInitiated) {
            do {
                let data: ItemShopDataResponse = try LocalDataService.load("item_shop")
                return data.shop
            } catch {
                logger.error("Failed to load item_shop.json: \(error.localizedDescription, privacy: .public)")
                assertionFailure("Failed to load item_shop.json: \(error)")
                return [:]
            }
        }

        loadTask = task
        let entriesByItemID = await task.value
        self.entriesByItemID = entriesByItemID
        loadTask = nil
        return entriesByItemID
    }
}

private let logger = Logger(subsystem: "EorzeaToolkit", category: "ItemShopDataService")
