//
//  ItemSearchQuery.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/11.
//

import Foundation

struct ItemSearchResult: Sendable {
    let items: [Item]
    let totalCount: Int
}

private struct ItemSearchMatch: Sendable {
    let item: Item
    let rank: Int
}

enum ItemSearchQuery {
    /// An empty query keeps every item the filter keeps, in the same order as a name search.
    static func searchItems(
        _ items: [Item],
        query: String,
        filter: ItemFilter,
        classjobJobSetsById: [Int: Set<String>]
    ) -> ItemSearchResult {
        let normalizedQuery = normalize(query)
        var matches: [ItemSearchMatch] = []

        for item in items {
            guard matchesFilter(item, filter: filter, classjobJobSetsById: classjobJobSetsById) else {
                continue
            }

            guard !normalizedQuery.isEmpty else {
                matches.append(ItemSearchMatch(item: item, rank: 0))
                continue
            }

            let normalizedName = normalize(item.nameTw)

            guard normalizedName.contains(normalizedQuery) else {
                continue
            }

            let rank: Int
            if normalizedName == normalizedQuery {
                rank = 0
            } else if normalizedName.hasPrefix(normalizedQuery) {
                rank = 1
            } else {
                rank = 2
            }

            matches.append(ItemSearchMatch(item: item, rank: rank))
        }

        matches.sort { lhs, rhs in
            if lhs.rank != rhs.rank {
                return lhs.rank < rhs.rank
            }

            if lhs.item.ilvl != rhs.item.ilvl {
                return lhs.item.ilvl > rhs.item.ilvl
            }

            return lhs.item.displayName.localizedStandardCompare(rhs.item.displayName) == .orderedAscending
        }

        return ItemSearchResult(items: matches.map(\.item), totalCount: matches.count)
    }
    
    /// The one item named `keyword`, compared as the name search compares names; nil when
    /// none or several are.
    static func onlyItemID(named keyword: String, in items: [Item]) -> Int? {
        let normalizedKeyword = normalize(keyword)
        var found: Int?
        for item in items where normalize(item.nameTw) == normalizedKeyword {
            guard found == nil else {
                return nil
            }
            found = item.id
        }
        return found
    }
    
    private static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
    
    private static func matchesFilter(
        _ item: Item,
        filter: ItemFilter,
        classjobJobSetsById: [Int: Set<String>]
    ) -> Bool {
        if item.ilvl == 0 {
            guard filter.ilvlRange == ItemFilter.defaultIlvlRange else {
                return false
            }
        } else if !filter.ilvlRange.contains(item.ilvl) {
            return false
        }

        // Only equipment is compared. Every other item has an equip level too (bait has the
        // level needed to use it), but once the range is narrowed those items drop out.
        if filter.equipLevelRange != ItemFilter.defaultEquipLevelRange {
            guard item.equipSlot != 0, filter.equipLevelRange.contains(item.equipLevel) else {
                return false
            }
        }

        guard filter.selectedRarities.contains(item.rarity) else {
            return false
        }

        switch filter.hqState {
        case .any:
            break
        case .only where !item.canBeHq:
            return false
        case .exclude where item.canBeHq:
            return false
        case .only, .exclude:
            break
        }

        switch filter.tradableState {
        case .any:
            break
        case .only where item.isUntradable:
            return false
        case .exclude where !item.isUntradable:
            return false
        case .only, .exclude:
            break
        }

        if !filter.selectedUICategoryIds.isEmpty,
           !filter.selectedUICategoryIds.contains(item.uiCategoryId) {
            return false
        }

        if !filter.selectedJobAbbrs.isEmpty {
            guard let jobSet = classjobJobSetsById[item.classjobCategoryId],
                  !jobSet.isDisjoint(with: filter.selectedJobAbbrs) else {
                return false
            }
        }

        if !filter.selectedEquipSlots.isEmpty,
           !filter.selectedEquipSlots.contains(item.equipSlot) {
            return false
        }

        return true
    }
}
