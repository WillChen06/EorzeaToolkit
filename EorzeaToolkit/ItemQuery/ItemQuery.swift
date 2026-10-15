import Foundation

/// What one sentence asks the item search for, with every name resolved to the ids and job
/// abbreviations the item filter uses. Empty sets and nil mean the sentence did not mention it.
struct ItemQuery: Equatable, Sendable {
    enum Usage: String, CaseIterable, Sendable {
        case search
        case recipe
        case unsupported

        /// The value the model picks for this usage. The evaluation set uses the same values.
        var label: String {
            switch self {
            case .search: return "搜尋"
            case .recipe: return "查配方"
            case .unsupported: return "無法處理"
            }
        }

        init?(label: String) {
            guard let usage = Self.allCases.first(where: { $0.label == label }) else {
                return nil
            }
            self = usage
        }
    }

    /// Matches `ItemFilter.defaultEquipLevelRange`, the equip level range the item filter offers.
    static let equipLevelBounds = 1...100
    /// Matches `ItemFilter.defaultIlvlRange`, the item level range the item filter offers.
    static let itemLevelBounds = 1...795

    var usage: Usage
    var keyword: String?
    var categoryIds: Set<Int> = []
    var equipSlotIds: Set<Int> = []
    var jobs: Set<String> = []
    var equipLevelRange: ClosedRange<Int>?
    var itemLevelRange: ClosedRange<Int>?
    var rarities: Set<Int> = []
    var hq: Bool?
    var tradable: Bool?
}

/// The parse result before resolution: the model's usage and keyword, and the conditions
/// matched in the sentence as names rather than ids, with level bounds as written.
///
/// The evaluation set writes its expected results in the same form, so the parse result and the
/// expected answer go through the same resolution before they are compared.
struct ItemQueryFields: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case usage
        case keyword
        case categories
        case slots
        case jobs
        case equipLevelMin
        case equipLevelMax
        case itemLevelMin
        case itemLevelMax
        case rarities
        case hq
        case tradable
    }

    var usage: String?
    var keyword: String?
    var categories: [String]?
    var slots: [String]?
    var jobs: [String]?
    var equipLevelMin: Int?
    var equipLevelMax: Int?
    var itemLevelMin: Int?
    var itemLevelMax: Int?
    var rarities: [String]?
    var hq: String?
    var tradable: String?

    init(
        usage: String? = nil,
        keyword: String? = nil,
        categories: [String]? = nil,
        slots: [String]? = nil,
        jobs: [String]? = nil,
        equipLevelMin: Int? = nil,
        equipLevelMax: Int? = nil,
        itemLevelMin: Int? = nil,
        itemLevelMax: Int? = nil,
        rarities: [String]? = nil,
        hq: String? = nil,
        tradable: String? = nil
    ) {
        self.usage = usage
        self.keyword = keyword
        self.categories = categories
        self.slots = slots
        self.jobs = jobs
        self.equipLevelMin = equipLevelMin
        self.equipLevelMax = equipLevelMax
        self.itemLevelMin = itemLevelMin
        self.itemLevelMax = itemLevelMax
        self.rarities = rarities
        self.hq = hq
        self.tradable = tradable
    }
}
