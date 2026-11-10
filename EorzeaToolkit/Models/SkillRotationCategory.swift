//
//  SkillRotationCategory.swift
//  EorzeaToolkit
//
//  Created by Kuan-Chung Chen on 2026/11/9.
//

enum SkillRotationCategory: String, CaseIterable, Identifiable {
    case all
    case weaponskill
    case spell
    case ability
    case item

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return L10n.SkillRotation.allCategoryText
        case .weaponskill: return SkillCategory.weaponskill.label
        case .spell: return SkillCategory.spell.label
        case .ability: return SkillCategory.ability.label
        case .item: return L10n.SkillRotation.itemCategoryText
        }
    }

    var skillCategory: SkillCategory? {
        switch self {
        case .weaponskill: return .weaponskill
        case .spell: return .spell
        case .ability: return .ability
        case .all, .item: return nil
        }
    }
}
