//
//  ItemDataClient.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/11.
//

import ComposableArchitecture

@DependencyClient
struct ItemDataClient: Sendable {
    var load: @Sendable () async throws -> ItemCatalog
    var refresh: @Sendable (_ currentVersion: String?) async throws -> ItemCatalog?
}

extension ItemDataClient: TestDependencyKey {
    static let testValue = Self()
}

extension ItemDataClient: DependencyKey {
    static let liveValue = Self(
        load: {
            let data = try await ItemDataService.loadCachedOrBundledData()
            return ItemCatalog(data: data)
        },
        refresh: { currentVersion in
            guard let data = try await ItemDataService.refreshDataIfNeeded(currentVersion: currentVersion) else {
                return nil
            }
            return ItemCatalog(data: data)
        }
    )
}

extension DependencyValues {
    var itemData: ItemDataClient {
        get { self[ItemDataClient.self] }
        set { self[ItemDataClient.self] = newValue }
    }
}

struct ItemCatalog: Equatable, Sendable {
    let items: [Item]
    let itemsByID: [Int: Item]
    let uiCategories: [UICategory]
    let equipSlots: [EquipSlot]
    let baseEquipSlots: [EquipSlot]
    let restrictedEquipSlots: [EquipSlot]
    let classjobJobSetsById: [Int: Set<String>]
    let version: String?
    
    init(data: ItemDataResponse) {
        self.items = data.items
        self.itemsByID = Dictionary(uniqueKeysWithValues: data.items.map { ($0.id, $0) })
        self.uiCategories = data.uiCategories
        self.equipSlots = data.equipSlots.filter { $0.id > 0 }
        (self.baseEquipSlots, self.restrictedEquipSlots) = EquipSlot.filterSections(self.equipSlots)
        self.classjobJobSetsById = Dictionary(
            uniqueKeysWithValues: data.classjobCategories.map { ($0.id, Set($0.jobs)) })
        self.version = data.version
    }
}
