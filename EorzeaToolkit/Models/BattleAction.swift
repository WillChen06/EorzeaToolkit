import Foundation

// MARK: - 戰鬥技能 JSON 資料（battle_actions.json）

struct BattleActionsData: Codable {
    let jobs: [BattleJob]
    let categoryNames: [String: [String: String]]?
    let tinctures: [Tincture]
    let tinctureStatJobs: [String: TinctureStatJob]

    enum CodingKeys: String, CodingKey {
        case jobs, tinctures
        case categoryNames = "category_names"
        case tinctureStatJobs = "tincture_stat_jobs"
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

struct Tincture: Codable, Identifiable, Hashable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let iconId: Int
    let iconPath: String
    let itemLevel: Int
    let stat: String

    enum CodingKeys: String, CodingKey {
        case id, stat
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case itemLevel = "item_level"
    }

    var displayName: String { nameTw }

    var iconURL: URL? {
        XIVIconURL.make(from: iconPath)
    }
}

struct TinctureStatJob: Codable, Hashable {
    let nameCn: String
    let nameTw: String
    let jobs: [String]

    enum CodingKeys: String, CodingKey {
        case jobs
        case nameCn = "name_cn"
        case nameTw = "name_tw"
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

enum SkillRotationLevel: Int, CaseIterable, Identifiable, Hashable, Codable {
    case level50 = 50
    case level60 = 60
    case level70 = 70
    case level80 = 80
    case level90 = 90
    case level100 = 100

    static let allCases: [SkillRotationLevel] = [
        .level100,
        .level90,
        .level80,
        .level70,
        .level60,
        .level50
    ]

    static let defaultLevel: SkillRotationLevel = .level100

    var id: Int { rawValue }

    var label: String {
        "Lv.\(rawValue)"
    }
}

enum RotationItem: Hashable, Codable {
    case action(BattleAction)
    case tincture(Tincture)

    var iconURL: URL? {
        switch self {
        case .action(let action): return action.iconURL
        case .tincture(let tincture): return tincture.iconURL
        }
    }

    var displayName: String {
        switch self {
        case .action(let action): return action.displayName
        case .tincture(let tincture): return tincture.displayName
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, action, tincture
    }

    private enum ItemType: String, Codable {
        case action, tincture
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)
        switch type {
        case .action:
            self = .action(try container.decode(BattleAction.self, forKey: .action))
        case .tincture:
            self = .tincture(try container.decode(Tincture.self, forKey: .tincture))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .action(let action):
            try container.encode(ItemType.action, forKey: .type)
            try container.encode(action, forKey: .action)
        case .tincture(let tincture):
            try container.encode(ItemType.tincture, forKey: .type)
            try container.encode(tincture, forKey: .tincture)
        }
    }
}

struct RotationSlot: Identifiable, Hashable, Codable {
    let id: UUID
    let item: RotationItem

    init(id: UUID = UUID(), action: BattleAction) {
        self.id = id
        self.item = .action(action)
    }

    init(id: UUID = UUID(), tincture: Tincture) {
        self.id = id
        self.item = .tincture(tincture)
    }
}

// MARK: - Icon URL Helper

enum XIVIconURL {
    static func make(from iconPath: String) -> URL? {
        URL(string: "https://beta.xivapi.com/api/1/asset/ui/icon/\(iconPath)?format=png")
    }
}
