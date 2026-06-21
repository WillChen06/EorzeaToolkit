import Foundation
import os

enum FishingDataService {
    private static let cache = FishingDataCache()

    static func spots(for itemID: Int) async -> [ItemFishingSpot] {
        await cache.spots(for: itemID)
    }
}

private actor FishingDataCache {
    private var fishingByItemID: [String: [ItemFishingSpot]]?
    private var loadTask: Task<[String: [ItemFishingSpot]], Never>?

    func spots(for itemID: Int) async -> [ItemFishingSpot] {
        let fishingByItemID = await loadFishingByItemID()
        return fishingByItemID[String(itemID), default: []]
    }

    private func loadFishingByItemID() async -> [String: [ItemFishingSpot]] {
        if let fishingByItemID {
            return fishingByItemID
        }

        if let loadTask {
            return await loadTask.value
        }

        let task = Task.detached(priority: .userInitiated) {
            do {
                let data: FishingDataResponse = try LocalDataService.load("fishing")
                return data.fishing.mapValues { spots in
                    spots.sorted {
                        if $0.level != $1.level {
                            return $0.level < $1.level
                        }

                        if $0.zoneID != $1.zoneID {
                            return $0.zoneID < $1.zoneID
                        }

                        if $0.x != $1.x {
                            return $0.x < $1.x
                        }

                        return $0.y < $1.y
                    }
                }
            } catch {
                logger.error("Failed to load fishing.json: \(error.localizedDescription, privacy: .public)")
                assertionFailure("Failed to load fishing.json: \(error)")
                return [:]
            }
        }

        loadTask = task
        let fishingByItemID = await task.value
        self.fishingByItemID = fishingByItemID
        loadTask = nil
        return fishingByItemID
    }
}

private let logger = Logger(subsystem: "EorzeaToolkit", category: "FishingDataService")
