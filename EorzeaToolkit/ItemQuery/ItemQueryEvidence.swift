import Foundation

/// The model's answer: every condition paired with the fragment of the sentence it is based on.
///
/// Asking for the fragment lets the parser check each condition against the sentence, which
/// `ItemQueryEvidence` does before the conditions become `ItemQueryFields`.
struct ItemQueryModelOutput: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case usage
        case keyword
        case categories
        case slots
        case jobs
        case equipLevel
        case itemLevel
        case rarities
        case hq
        case tradable
    }

    /// A name picked from one of the vocabulary's lists.
    struct Choice: Codable, Equatable, Sendable {
        var quote: String?
        var name: String?
    }

    struct Levels: Codable, Equatable, Sendable {
        var quote: String?
        var min: Int?
        var max: Int?
    }

    struct Flag: Codable, Equatable, Sendable {
        var quote: String?
        var value: String?
    }

    /// The keys inside the nested objects, shared with the schema and the instructions.
    enum NestedKey: String {
        case quote
        case name
        case min
        case max
        case value
    }

    var usage: String?
    var keyword: String?
    var categories: [Choice]?
    var slots: [Choice]?
    var jobs: [Choice]?
    var equipLevel: Levels?
    var itemLevel: Levels?
    var rarities: [Choice]?
    var hq: Flag?
    var tradable: Flag?

    init(
        usage: String? = nil,
        keyword: String? = nil,
        categories: [Choice]? = nil,
        slots: [Choice]? = nil,
        jobs: [Choice]? = nil,
        equipLevel: Levels? = nil,
        itemLevel: Levels? = nil,
        rarities: [Choice]? = nil,
        hq: Flag? = nil,
        tradable: Flag? = nil
    ) {
        self.usage = usage
        self.keyword = keyword
        self.categories = categories
        self.slots = slots
        self.jobs = jobs
        self.equipLevel = equipLevel
        self.itemLevel = itemLevel
        self.rarities = rarities
        self.hq = hq
        self.tradable = tradable
    }
}

/// Keeps only the conditions the sentence supports.
///
/// A small model tends to fill fields the sentence never mentions, often with values copied
/// from its instructions. A condition survives only when its quoted fragment appears in the
/// sentence; a level bound also needs its number in that fragment; and the keyword must itself
/// appear in the sentence.
enum ItemQueryEvidence {
    static func fields(from output: ItemQueryModelOutput, sentence: String) -> ItemQueryFields {
        let text = normalized(sentence)

        func supported(_ fragment: String?) -> Bool {
            guard let fragment = fragment.map(normalized), !fragment.isEmpty else {
                return false
            }
            return text.contains(fragment)
        }

        func names(_ choices: [ItemQueryModelOutput.Choice]?) -> [String]? {
            let kept = (choices ?? []).filter { supported($0.quote) }.compactMap(\.name)
            return kept.isEmpty ? nil : kept
        }

        func bound(_ value: Int?, of levels: ItemQueryModelOutput.Levels?) -> Int? {
            guard let value, let levels, supported(levels.quote),
                  normalized(levels.quote ?? "").contains(String(value)) else {
                return nil
            }
            return value
        }

        func flag(_ flag: ItemQueryModelOutput.Flag?) -> String? {
            guard let flag, supported(flag.quote) else {
                return nil
            }
            return flag.value
        }

        return ItemQueryFields(
            usage: output.usage,
            keyword: supported(output.keyword) ? output.keyword : nil,
            categories: names(output.categories),
            slots: names(output.slots),
            jobs: names(output.jobs),
            equipLevelMin: bound(output.equipLevel?.min, of: output.equipLevel),
            equipLevelMax: bound(output.equipLevel?.max, of: output.equipLevel),
            itemLevelMin: bound(output.itemLevel?.min, of: output.itemLevel),
            itemLevelMax: bound(output.itemLevel?.max, of: output.itemLevel),
            rarities: names(output.rarities),
            hq: flag(output.hq),
            tradable: flag(output.tradable)
        )
    }

    /// Half-width, lower-cased and without whitespace, so 「MCH」 matches 「mch」, 「iLv600」
    /// matches 「iLv 600」 and 「80級」 matches 「８０級」.
    static func normalized(_ text: String) -> String {
        let halfWidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return String(halfWidth.lowercased().filter { !$0.isWhitespace })
    }
}
