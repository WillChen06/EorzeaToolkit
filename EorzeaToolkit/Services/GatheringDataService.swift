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
    private var loadTask: Task<[String: [ItemGatheringNode]], Never>?

    func nodes(for itemID: Int) async -> [ItemGatheringNode] {
        let gatheringByItemID = await loadGatheringByItemID()
        return gatheringByItemID[String(itemID), default: []]
    }

    private func loadGatheringByItemID() async -> [String: [ItemGatheringNode]] {
        if let gatheringByItemID {
            return gatheringByItemID
        }

        if let loadTask {
            return await loadTask.value
        }

        let task = Task.detached(priority: .userInitiated) {
            do {
                let data: GatheringDataResponse = try LocalDataService.load("gathering")
                return data.gathering
            } catch {
                logger.error("Failed to load gathering.json: \(error.localizedDescription, privacy: .public)")
                assertionFailure("Failed to load gathering.json: \(error)")
                return [:]
            }
        }

        loadTask = task
        let gatheringByItemID = await task.value
        self.gatheringByItemID = gatheringByItemID
        loadTask = nil
        return gatheringByItemID
    }
}

private let logger = Logger(subsystem: "EorzeaToolkit", category: "GatheringDataService")
