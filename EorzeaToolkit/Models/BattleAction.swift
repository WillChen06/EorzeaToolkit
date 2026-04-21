import Foundation

// MARK: - 戰鬥技能 JSON 資料（battle_actions.json）

struct BattleActionsData: Codable {
    let jobs: [BattleJob]
    let categoryNames: [String: [String: String]]?

    enum CodingKeys: String, CodingKey {
        case jobs
        case categoryNames = "category_names"
    }
}

struct BattleJob: Codable, Identifiable, Hashable {
    let id: Int
    let nameCn: String
    let nameTw: String?
    let abbreviation: String
    let iconId: Int
    let iconPath: String
    let actions: [BattleAction]

    enum CodingKeys: String, CodingKey {
        case id, abbreviation, actions
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
    }

    var displayName: String { nameTw ?? nameCn }

    var iconURL: URL? {
        XIVIconURL.make(from: iconPath)
    }

    var availableCategories: [SkillCategory] {
        let set = Set(actions.compactMap { $0.skillCategory })
        return SkillCategory.allCases.filter { set.contains($0) }
    }
}

struct BattleAction: Codable, Identifiable, Hashable {
    let id: Int
    let nameCn: String
    let nameTw: String?
    let iconId: Int
    let iconPath: String
    let category: String
    let level: Int
    let range: Int
    let effectRange: Int
    let cast100ms: Int
    let recast100ms: Int
    let maxCharges: Int
    let descriptionCn: String?
    let descriptionTw: String?

    enum CodingKeys: String, CodingKey {
        case id, category, level, range
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case effectRange = "effect_range"
        case cast100ms = "cast_100ms"
        case recast100ms = "recast_100ms"
        case maxCharges = "max_charges"
        case descriptionCn = "description_cn"
        case descriptionTw = "description_tw"
    }

    var displayName: String { nameTw ?? nameCn }

    var iconURL: URL? {
        XIVIconURL.make(from: iconPath)
    }

    var skillCategory: SkillCategory? {
        SkillCategory(rawValue: category)
    }

    var rangeText: String {
        switch range {
        case -1: return "近戰"
        case 0: return "自身"
        default: return "\(range) 米"
        }
    }

    var effectRangeText: String? {
        effectRange > 1 ? "\(effectRange) 米" : nil
    }

    var castText: String {
        cast100ms == 0 ? "即時" : String(format: "%.1f 秒", Double(cast100ms) / 10.0)
    }

    var recastText: String? {
        recast100ms > 0 ? String(format: "%.1f 秒", Double(recast100ms) / 10.0) : nil
    }

    /// 移除遊戲內條件判斷模板（如 `<If(...)>`），讓說明文字較易閱讀。
    var cleanedDescription: String {
        let raw = descriptionTw ?? descriptionCn ?? ""
        let pattern = #"<[^>]+>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return raw }
        let range = NSRange(raw.startIndex..., in: raw)
        let stripped = regex.stringByReplacingMatches(in: raw, range: range, withTemplate: "")
        return stripped
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

// MARK: - 技能分類

enum SkillCategory: String, CaseIterable, Identifiable, Hashable {
    case weaponskill
    case spell
    case ability

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weaponskill: return "戰技"
        case .spell: return "魔法"
        case .ability: return "能力"
        }
    }
}

// MARK: - Rotation（編輯區）

struct RotationSlot: Identifiable, Hashable, Codable {
    let id: UUID
    let action: BattleAction

    init(id: UUID = UUID(), action: BattleAction) {
        self.id = id
        self.action = action
    }
}

// MARK: - Icon URL Helper

enum XIVIconURL {
    static func make(from iconPath: String) -> URL? {
        URL(string: "https://beta.xivapi.com/api/1/asset/ui/icon/\(iconPath)?format=png")
    }
}
