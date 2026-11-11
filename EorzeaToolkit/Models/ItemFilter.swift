//
//  ItemFilter.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/11.
//

import Foundation

enum ItemBoolFilterState: String, CaseIterable, Sendable {
    case any
    case only
    case exclude
}

struct ItemFilter: Equatable, Sendable {
    static let defaultIlvlRange = 1...795
    /// Equip levels run from 1 to the level cap. Raise the upper bound with the cap:
    /// `scripts/validate_data.py` fails when an item's equip level is above it.
    static let defaultEquipLevelRange = 1...100
    static let defaultRarities: Set<Int> = [1, 2, 3, 4, 7]

    var ilvlRange: ClosedRange<Int> = Self.defaultIlvlRange
    /// Narrowing it keeps only equippable items whose equip level is in the range.
    var equipLevelRange: ClosedRange<Int> = Self.defaultEquipLevelRange
    var selectedRarities: Set<Int> = Self.defaultRarities
    var hqState: ItemBoolFilterState = .any
    var tradableState: ItemBoolFilterState = .any
    var selectedUICategoryIds: Set<Int> = []
    var selectedJobAbbrs: Set<String> = []
    var selectedEquipSlots: Set<Int> = []

    var isActive: Bool {
        ilvlRange != Self.defaultIlvlRange ||
            equipLevelRange != Self.defaultEquipLevelRange ||
            selectedRarities != Self.defaultRarities ||
            hqState != .any ||
            tradableState != .any ||
            !selectedUICategoryIds.isEmpty ||
            !selectedJobAbbrs.isEmpty ||
            !selectedEquipSlots.isEmpty
    }

    var activeFilterCount: Int {
        var count = 0

        if ilvlRange != Self.defaultIlvlRange {
            count += 1
        }

        if equipLevelRange != Self.defaultEquipLevelRange {
            count += 1
        }

        if selectedRarities != Self.defaultRarities {
            count += 1
        }

        if hqState != .any {
            count += 1
        }

        if tradableState != .any {
            count += 1
        }

        if !selectedUICategoryIds.isEmpty {
            count += 1
        }

        if !selectedJobAbbrs.isEmpty {
            count += 1
        }

        if !selectedEquipSlots.isEmpty {
            count += 1
        }

        return count
    }

    var summaryParts: [String] {
        var parts: [String] = []

        if ilvlRange != Self.defaultIlvlRange {
            parts.append(L10n.ItemSearch.Filter.summaryItemLevel(
                lowerBound: ilvlRange.lowerBound,
                upperBound: ilvlRange.upperBound
            ))
        }

        if equipLevelRange != Self.defaultEquipLevelRange {
            parts.append(L10n.ItemSearch.Filter.summaryEquipLevel(
                lowerBound: equipLevelRange.lowerBound,
                upperBound: equipLevelRange.upperBound
            ))
        }

        if selectedRarities != Self.defaultRarities {
            if selectedRarities.isEmpty {
                parts.append(L10n.ItemSearch.Filter.noRaritySummaryText)
            } else {
                let names = selectedRarities
                    .sorted()
                    .compactMap { Self.rarityName(for: $0) }
                    .joined(separator: L10n.ItemSearch.Filter.summaryListSeparator)
                parts.append(L10n.ItemSearch.Filter.raritySummary(names))
            }
        }

        switch hqState {
        case .any:
            break
        case .only:
            parts.append(L10n.ItemSearch.Filter.hqOnlySummaryText)
        case .exclude:
            parts.append(L10n.ItemSearch.Filter.hqExcludeSummaryText)
        }

        switch tradableState {
        case .any:
            break
        case .only:
            parts.append(L10n.ItemSearch.Filter.tradableOnlySummaryText)
        case .exclude:
            parts.append(L10n.ItemSearch.Filter.tradableExcludeSummaryText)
        }

        return parts
    }

    func summaryParts(
        uiCategoryNamesById: [Int: String],
        jobNamesByAbbr: [String: String],
        equipSlotNamesById: [Int: String]
    ) -> [String] {
        var parts = summaryParts

        appendSelectionSummary(
            from: selectedUICategoryIds,
            lookup: uiCategoryNamesById,
            fallbackName: { L10n.ItemSearch.Filter.categoryFallbackName(id: $0) },
            countSummary: L10n.ItemSearch.Filter.categorySelectionCount(_:),
            to: &parts
        )
        appendSelectionSummary(
            from: selectedEquipSlots,
            lookup: equipSlotNamesById,
            fallbackName: { L10n.ItemSearch.Filter.equipSlotFallbackName(id: $0) },
            countSummary: L10n.ItemSearch.Filter.equipSlotSelectionCount(_:),
            to: &parts
        )
        appendSelectionSummary(
            from: selectedJobAbbrs,
            lookup: jobNamesByAbbr,
            fallbackName: L10n.ItemSearch.Filter.jobFallbackName(abbreviation:),
            countSummary: L10n.ItemSearch.Filter.jobSelectionCount(_:),
            to: &parts
        )

        if parts.count > 3 {
            return [L10n.ItemSearch.Filter.activeFilterSummary(count: activeFilterCount)]
        }

        return parts
    }

    static func rarityName(for rarity: Int) -> String? {
        L10n.ItemSearch.Filter.rarityName(rarity)
    }

    private func appendSelectionSummary<T: Comparable>(
        from selection: Set<T>,
        lookup: [T: String],
        fallbackName: (T) -> String,
        countSummary: (Int) -> String,
        to parts: inout [String]
    ) {
        guard !selection.isEmpty else {
            return
        }

        let names = selection
            .sorted()
            .map { lookup[$0] ?? fallbackName($0) }

        if names.count <= 2 {
            parts.append(contentsOf: names)
        } else {
            parts.append(countSummary(names.count))
        }
    }
}
