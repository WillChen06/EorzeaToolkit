import Foundation

/// Finds the conditions a sentence states by matching names: categories, body parts, jobs and
/// rarities. Only the usage and the keyword are left to the model.
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
        let candidates = nameMatches(in: text)
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

    // MARK: - Text

    /// Half-width, lower-cased and without whitespace, so 「MCH」 matches 「mch」, 「iLv 600」
    /// matches 「ilv600」 and 「８０級」 matches 「80級」.
    static func normalized(_ text: String) -> String {
        let halfWidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return String(halfWidth.lowercased().filter { !$0.isWhitespace })
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
