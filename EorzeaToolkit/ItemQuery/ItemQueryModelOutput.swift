import Foundation

/// The model's answer: whether the sentence searches, asks for a recipe or cannot be handled,
/// and the part of it that names an item. Every other condition comes from the sentence itself
/// (`ItemQueryMatcher`).
struct ItemQueryModelOutput: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case usage
        case keyword
    }

    var usage: String?
    var keyword: String?
}

// MARK: - Plain text

/// The model answers in plain text, one 「標籤：值」 line per field, because the permissive
/// guardrails only apply to plain text answers.
extension ItemQueryModelOutput {
    static let usageLabel = "用法"
    static let keywordLabel = "關鍵字"
    /// Values that mean there is no keyword, for a model that writes the line anyway.
    static let noKeywordValues: Set<String> = ["無", "沒有"]

    private static let separators: Set<Character> = ["：", ":"]
    private static let labelDecoration = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "-*#"))
    private static let quotePairs: [(Character, Character)] = [
        ("「", "」"), ("『", "』"), ("\"", "\""), ("“", "”"), ("'", "'")
    ]

    /// The answer as the model should write it.
    var text: String {
        var lines = ["\(Self.usageLabel)：\(usage ?? "")"]
        if let keyword {
            lines.append("\(Self.keywordLabel)：\(keyword)")
        }
        return lines.joined(separator: "\n")
    }

    /// Reads the model's plain text answer. Nil when it has no usage line or the usage is not
    /// one of the three, which is also what a refusal message looks like.
    init?(text: String) {
        var usage: String?
        var keyword: String?
        for line in text.split(whereSeparator: \.isNewline) {
            guard let field = Self.field(in: line) else {
                continue
            }
            if field.label == Self.usageLabel, usage == nil {
                usage = field.value
            } else if field.label == Self.keywordLabel, keyword == nil {
                keyword = field.value
            }
        }

        guard let usage, ItemQuery.Usage(label: usage) != nil else {
            return nil
        }
        self.usage = usage
        self.keyword = keyword.flatMap { $0.isEmpty || Self.noKeywordValues.contains($0) ? nil : $0 }
    }

    /// 「用法：搜尋」 → (用法, 搜尋). Whitespace and Markdown marks around the label, and whitespace
    /// and a pair of quotes around the value, are removed: 「- **用法**：「搜尋」」 reads the same.
    private static func field(in line: Substring) -> (label: String, value: String)? {
        guard let separator = line.firstIndex(where: { separators.contains($0) }) else {
            return nil
        }
        let label = line[..<separator].trimmingCharacters(in: labelDecoration)
        var value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
        if let first = value.first, let last = value.last, value.count >= 2,
           quotePairs.contains(where: { $0.0 == first && $0.1 == last }) {
            value = String(value.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        }
        return (label, value)
    }
}
