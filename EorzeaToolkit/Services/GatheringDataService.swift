import Foundation
import os

enum GatheringDataService {
    private static let cache = GatheringDataCache()

    static func nodes(for itemID: Int) async -> [ItemGatheringNode] {
        await cache.nodes(for: itemID)
    }
}

private actor GatheringDataCache {
    private var gatheringByItemID: [String: [ItemGatheringNode]]?

    func nodes(for itemID: Int) -> [ItemGatheringNode] {
        if let gatheringByItemID {
            return gatheringByItemID[String(itemID), default: []]
        }

        do {
            let data: GatheringDataResponse = try LocalDataService.load("gathering")
            gatheringByItemID = data.gathering
            return data.gathering[String(itemID), default: []]
        } catch {
            logger.error("Failed to load gathering.json: \(error.localizedDescription, privacy: .public)")
            assertionFailure("Failed to load gathering.json: \(error)")
            gatheringByItemID = [:]
            return []
        }
    }
}

private let logger = Logger(subsystem: "EorzeaToolkit", category: "GatheringDataService")
