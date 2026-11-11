//
//  UICategoryGroup.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/11.
//

struct UICategoryGroup: Identifiable, Sendable {
    let orderMajor: Int
    let title: String
    let categories: [UICategory]

    var id: Int { orderMajor }
}
