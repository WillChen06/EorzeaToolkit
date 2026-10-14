import Foundation

/// Finds the conditions a sentence states by matching names and number patterns: categories,
/// body parts, jobs, rarities, levels, HQ and tradability. Only the usage and the keyword are
/// left to the model.
///
/// In the first two evaluation runs the model picked the wrong names even when a sentence
/// spelled them out. Matching gives the same answer every time and can be unit tested. The
/// sentence and every name are normalised the same way before they are compared: half-width,
/// lower-cased and without whitespace.
struct ItemQueryMatcher: Sendable {
    enum Condition: Equatable, Sendable {
        /// Category names.
        case categories([String])
        case slot(String)
        /// A job abbreviation.
        case job(String)
        /// A rarity name.
        case rarity(String)
        case equipLevel(min: Int?, max: Int?)
        case itemLevel(min: Int?, max: Int?)
        case hq(Bool)
        case tradable(Bool)
    }

    /// A condition and where it was found, in characters of the normalised sentence.
    struct Match: Equatable, Sendable {
        let range: Range<Int>
        let condition: Condition
    }

    private struct Name: Sendable {
        let text: [Character]
        let condition: Condition
    }

    /// Every name the matcher looks for. No two share a text.
    private let names: [Name]

    init(vocabulary: ItemQueryVocabulary) {
        var names: [Name] = []
        var seen: Set<String> = []
        func add(_ name: String, _ condition: Condition) {
            let text = Self.normalized(name)
            guard !text.isEmpty, seen.insert(text).inserted else {
                return
            }
            names.append(Name(text: Array(text), condition: condition))
        }

        // When two lists share a name, the earlier list wins: 戒指 is a body part before it is a
        // category.
        for slot in vocabulary.slots {
            add(slot.name, .slot(slot.name))
        }
        for category in vocabulary.categories {
            add(category.name, .categories([category.name]))
        }
        for job in vocabulary.jobs {
            for name in [job.abbreviation] + [job.officialName].compactMap({ $0 }) + job.nicknames {
                add(name, .job(job.abbreviation))
            }
        }
        for rarity in ItemQueryVocabulary.rarities {
            add(rarity.name, .rarity(rarity.name))
            add(rarity.colour + "色", .rarity(rarity.name))
            add(rarity.colour + "裝", .rarity(rarity.name))
        }

        self.names = names
    }

    // MARK: - Matching

    /// Every condition in the sentence, in the order they appear. Where two overlap the longer
    /// one wins, so 龍騎士 is not also 騎士 and 武士刀 is not also 武士.
    func matches(in sentence: String) -> [Match] {
        matches(in: Array(Self.normalized(sentence)))
    }

    private func matches(in text: [Character]) -> [Match] {
        let candidates = nameMatches(in: text) + Self.levelMatches(in: text) + Self.flagMatches(in: text)
        let longestFirst = candidates.enumerated().sorted { lhs, rhs in
            let (left, right) = (lhs.element.range, rhs.element.range)
            if left.count != right.count {
                return left.count > right.count
            }
            if left.lowerBound != right.lowerBound {
                return left.lowerBound < right.lowerBound
            }
            return lhs.offset < rhs.offset
        }

        var taken = Array(repeating: false, count: text.count)
        var kept: [Match] = []
        for (_, match) in longestFirst where !match.range.contains(where: { taken[$0] }) {
            kept.append(match)
            for index in match.range {
                taken[index] = true
            }
        }
        return kept.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    private func nameMatches(in text: [Character]) -> [Match] {
        names.flatMap { name in
            Self.occurrences(of: name.text, in: text)
                .filter { Self.standsAlone($0, in: text) }
                .map { Match(range: $0, condition: name.condition) }
        }
    }

    // MARK: - Levels

    private enum LevelKind {
        case equip
        case item
    }

    private struct LevelMarker {
        let text: [Character]
        let kind: LevelKind

        init(_ text: String, _ kind: LevelKind) {
            self.text = Array(text)
            self.kind = kind
        }
    }

    /// Words before a number that make it a level. Longer ones come first, so iLv is not read as
    /// Lv; 品級 also ends in 級 but is a word before the number, not after it.
    private static let levelMarkers = [
        LevelMarker("品級", .item),
        LevelMarker("裝等", .item),
        LevelMarker("ilvl", .item),
        LevelMarker("ilv", .item),
        LevelMarker("等級", .equip),
        LevelMarker("lvl", .equip),
        LevelMarker("lv", .equip)
    ]
    /// May sit between a marker and its number, as in Lv.80.
    private static let levelSeparators: Set<Character> = [".", ":"]
    private static let rangeConnectors: Set<Character> = ["到", "至", "~", "〜", "-", "–", "—"]

    /// 「80級」「等級80」「Lv.80」, optionally followed by 以上, 以下 or 以內, and ranges such as
    /// 「70到80級」. A number counts only with a marker before it or 級 after it, and is always
    /// read whole, so 700 is never 70.
    private static func levelMatches(in text: [Character]) -> [Match] {
        var matches: [Match] = []
        var index = 0
        while index < text.count {
            guard let first = number(at: index, in: text) else {
                index += 1
                continue
            }

            let marker = levelMarker(before: index, in: text)
            var end = first.end
            var saysLevel = false
            if end < text.count, text[end] == "級" {
                end += 1
                saysLevel = true
            }

            var second: Int?
            if end < text.count, rangeConnectors.contains(text[end]), let next = number(at: end + 1, in: text) {
                second = next.value
                end = next.end
                if end < text.count, text[end] == "級" {
                    end += 1
                    saysLevel = true
                }
            }

            guard marker != nil || saysLevel else {
                index = first.end
                continue
            }

            var lower: Int? = first.value
            var upper: Int? = second ?? first.value
            if second == nil {
                if hasWord("以上", at: end, in: text) {
                    upper = nil
                    end += 2
                } else if hasWord("以下", at: end, in: text) || hasWord("以內", at: end, in: text) {
                    lower = nil
                    end += 2
                }
            }

            let condition: Condition = marker?.kind == .item
                ? .itemLevel(min: lower, max: upper)
                : .equipLevel(min: lower, max: upper)
            matches.append(Match(range: (marker?.start ?? index)..<end, condition: condition))
            index = end
        }
        return matches
    }

    private static func number(at index: Int, in text: [Character]) -> (value: Int, end: Int)? {
        var end = index
        while end < text.count, text[end].isASCII, text[end].isNumber {
            end += 1
        }
        guard end > index, let value = Int(String(text[index..<end])) else {
            return nil
        }
        return (value, end)
    }

    private static func levelMarker(before index: Int, in text: [Character]) -> (kind: LevelKind, start: Int)? {
        var end = index
        if end > 0, levelSeparators.contains(text[end - 1]) {
            end -= 1
        }
        for marker in levelMarkers {
            let start = end - marker.text.count
            guard start >= 0, text[start..<end].elementsEqual(marker.text) else {
                continue
            }
            if isLatinOrDigit(marker.text[0]), start > 0, isLatinOrDigit(text[start - 1]) {
                continue
            }
            return (marker.kind, start)
        }
        return nil
    }

    // MARK: - HQ and tradability

    private static let hqWord = Array("hq")
    private static let tradableWords = ["交易", "買賣", "市場板"].map { Array($0) }
    private static let negations: Set<Character> = ["不", "無", "沒", "非", "禁"]
    /// Punctuation (after normalisation) and conjunctions that end a clause, so 「不要藍色的，
    /// 可以交易」 is not read as 「不…交易」.
    private static let clauseBreaks: Set<Character> = [",", "、", "､", "。", "｡", ";", "!", "?", "又", "但"]
    /// How far back a negation still applies, in characters: 「不可以HQ」 reaches four.
    private static let negationReach = 4

    /// 「HQ」 is a condition on HQ and 「交易」「買賣」「市場板」 one on tradability, negative when
    /// a negation comes shortly before it in the same clause.
    private static func flagMatches(in text: [Character]) -> [Match] {
        var matches: [Match] = []
        for range in occurrences(of: hqWord, in: text) where standsAlone(range, in: text) {
            matches.append(Match(range: range, condition: .hq(!isNegated(before: range.lowerBound, in: text))))
        }
        for word in tradableWords {
            for range in occurrences(of: word, in: text) {
                matches.append(Match(range: range, condition: .tradable(!isNegated(before: range.lowerBound, in: text))))
            }
        }
        return matches
    }

    private static func isNegated(before index: Int, in text: [Character]) -> Bool {
        var position = index - 1
        var reach = 0
        while position >= 0, reach < negationReach, !clauseBreaks.contains(text[position]) {
            if negations.contains(text[position]) {
                return true
            }
            position -= 1
            reach += 1
        }
        return false
    }

    // MARK: - Text

    /// Half-width, lower-cased and without whitespace, so 「MCH」 matches 「mch」, 「iLv 600」
    /// matches 「ilv600」 and 「８０級」 matches 「80級」.
    static func normalized(_ text: String) -> String {
        let halfWidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return String(halfWidth.lowercased().filter { !$0.isWhitespace })
    }

    private static func hasWord(_ word: String, at index: Int, in text: [Character]) -> Bool {
        let word = Array(word)
        return index + word.count <= text.count && text[index..<(index + word.count)].elementsEqual(word)
    }

    private static func occurrences(of word: [Character], in text: [Character]) -> [Range<Int>] {
        guard !word.isEmpty, word.count <= text.count else {
            return []
        }
        return (0...(text.count - word.count))
            .map { $0..<($0 + word.count) }
            .filter { text[$0].elementsEqual(word) }
    }

    /// A match that begins or ends with a Latin letter or digit must not run into another one,
    /// so MCH is found in 「mch的火槍」 but not inside a longer word.
    private static func standsAlone(_ range: Range<Int>, in text: [Character]) -> Bool {
        if isLatinOrDigit(text[range.lowerBound]), range.lowerBound > 0, isLatinOrDigit(text[range.lowerBound - 1]) {
            return false
        }
        if isLatinOrDigit(text[range.upperBound - 1]), range.upperBound < text.count, isLatinOrDigit(text[range.upperBound]) {
            return false
        }
        return true
    }

    private static func isLatinOrDigit(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber)
    }
}
