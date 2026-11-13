//
//  UICategoryGroup.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/11.
//

import Foundation

struct UICategoryGroup: Identifiable, Sendable {
    let orderMajor: Int
    let title: String
    let categories: [UICategory]

    var id: Int { orderMajor }
}

extension UICategoryGroup {
    static func groups(from categories: [UICategory]) -> [UICategoryGroup] {
        let grouped = Dictionary(grouping: categories) { $0.orderMajor }

        return grouped.keys.sorted().map { orderMajor in
            UICategoryGroup(
                orderMajor: orderMajor,
                title: L10n.ItemSearch.Filter.categoryGroupTitle(orderMajor: orderMajor),
                categories: grouped[orderMajor, default: []].sorted {
                    if $0.orderMinor != $1.orderMinor {
                        return $0.orderMinor < $1.orderMinor
                    }

                    return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
                }
            )
        }
    }
}
