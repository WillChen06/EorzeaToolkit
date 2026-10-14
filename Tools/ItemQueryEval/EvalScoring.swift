import Foundation

/// The model's answer to one case.
struct EvalOutcome {
    enum Result {
        case parsed(ItemQuery)
        /// The model's guardrails declined the sentence.
        case blocked(String)
        /// Any other error.
        case failed(String)
    }

    let evalCase: EvalCase
    let expected: ItemQuery
    let result: Result
    let seconds: Double

    var actual: ItemQuery? {
        if case .parsed(let query) = result {
            return query
        }
        return nil
    }

    var isFullMatch: Bool {
        actual == expected
    }
}

/// One field of the parse result, compared after names are resolved to ids.
enum EvalField: CaseIterable {
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

    var title: String {
        switch self {
        case .usage: return "用法"
        case .keyword: return "關鍵字"
        case .categories: return "分類"
        case .slots: return "部位"
        case .jobs: return "職業"
        case .equipLevel: return "裝備等級"
        case .itemLevel: return "品級"
        case .rarities: return "稀有度"
        case .hq: return "HQ"
        case .tradable: return "可交易"
        }
    }

    /// The spec's threshold for continuing to the app: 90% for usage and keyword, 85% for the rest.
    var threshold: Double {
        switch self {
        case .usage, .keyword: return 0.9
        default: return 0.85
        }
    }

    func hasValue(_ query: ItemQuery) -> Bool {
        switch self {
        case .usage: return true
        case .keyword: return query.keyword != nil
        case .categories: return !query.categoryIds.isEmpty
        case .slots: return !query.equipSlotIds.isEmpty
        case .jobs: return !query.jobs.isEmpty
        case .equipLevel: return query.equipLevelRange != nil
        case .itemLevel: return query.itemLevelRange != nil
        case .rarities: return !query.rarities.isEmpty
        case .hq: return query.hq != nil
        case .tradable: return query.tradable != nil
        }
    }

    func matches(_ expected: ItemQuery, _ actual: ItemQuery) -> Bool {
        switch self {
        case .usage: return expected.usage == actual.usage
        case .keyword: return expected.keyword == actual.keyword
        case .categories: return expected.categoryIds == actual.categoryIds
        case .slots: return expected.equipSlotIds == actual.equipSlotIds
        case .jobs: return expected.jobs == actual.jobs
        case .equipLevel: return expected.equipLevelRange == actual.equipLevelRange
        case .itemLevel: return expected.itemLevelRange == actual.itemLevelRange
        case .rarities: return expected.rarities == actual.rarities
        case .hq: return expected.hq == actual.hq
        case .tradable: return expected.tradable == actual.tradable
        }
    }

    /// The field's value in the vocabulary's names and order, so two runs print the same text.
    func text(_ query: ItemQuery, vocabulary: ItemQueryVocabulary) -> String {
        func list(_ names: [String]) -> String {
            names.isEmpty ? "—" : names.joined(separator: "、")
        }
        func range(_ value: ClosedRange<Int>?) -> String {
            value.map { "\($0.lowerBound)–\($0.upperBound)" } ?? "—"
        }
        func flag(_ value: Bool?, _ labels: ItemQueryVocabulary.FlagLabels) -> String {
            value.map { $0 ? labels.yes : labels.no } ?? "—"
        }

        switch self {
        case .usage:
            return query.usage.label
        case .keyword:
            return query.keyword ?? "—"
        case .categories:
            return list(vocabulary.categories.filter { !query.categoryIds.isDisjoint(with: $0.ids) }.map(\.name))
        case .slots:
            return list(vocabulary.slots.filter { !query.equipSlotIds.isDisjoint(with: $0.ids) }.map(\.name))
        case .jobs:
            return list(vocabulary.jobs.map(\.abbreviation).filter { query.jobs.contains($0) })
        case .equipLevel:
            return range(query.equipLevelRange)
        case .itemLevel:
            return range(query.itemLevelRange)
        case .rarities:
            return list(ItemQueryVocabulary.rarities.filter { query.rarities.contains($0.id) }.map(\.name))
        case .hq:
            return flag(query.hq, ItemQueryVocabulary.hqLabels)
        case .tradable:
            return flag(query.tradable, ItemQueryVocabulary.tradableLabels)
        }
    }
}

/// A field's accuracy, scored as the spec defines it: only over cases where the expected or the
/// actual value is set. A blocked or failed case has no actual value, so it counts as wrong in
/// every field it was expected to fill.
struct FieldScore {
    let field: EvalField
    let correct: Int
    let total: Int

    var ratio: Double? {
        total == 0 ? nil : Double(correct) / Double(total)
    }

    /// Nil when no case has a value for this field, so there is nothing to judge.
    var meetsThreshold: Bool? {
        ratio.map { $0 >= field.threshold }
    }

    static func scores(for outcomes: [EvalOutcome]) -> [FieldScore] {
        EvalField.allCases.map { field in
            var correct = 0
            var total = 0
            for outcome in outcomes {
                guard let actual = outcome.actual else {
                    if field.hasValue(outcome.expected) {
                        total += 1
                    }
                    continue
                }
                guard field.hasValue(outcome.expected) || field.hasValue(actual) else {
                    continue
                }
                total += 1
                if field.matches(outcome.expected, actual) {
                    correct += 1
                }
            }
            return FieldScore(field: field, correct: correct, total: total)
        }
    }
}
