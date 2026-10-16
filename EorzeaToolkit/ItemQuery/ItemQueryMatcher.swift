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
        /// Category names. A partial name such as 採掘工具 or 副工具 stands for several.
        case categories([String])
        /// Body part names. One name stands for one body part, unless it names a group.
        case slots([String])
        /// Job abbreviations. One name stands for one job, unless it names a group.
        case jobs([String])
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

    private let vocabulary: ItemQueryVocabulary
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

        // 採掘工具（主工具） also matches without its brackets, and either part alone (採掘工具,
        // 主工具) stands for every category that has it, along with a category of that very
        // name: 魔導書 is also 魔導書（學者專用）.
        var unbracketedNames: [(text: String, category: String)] = []
        var partialNames: [String] = []
        var categoriesByPartialName: [String: [String]] = [:]
        for category in vocabulary.categories {
            guard let parts = Self.bracketedParts(of: category.name) else {
                continue
            }
            unbracketedNames.append((parts.outer + parts.inner, category.name))
            for part in [parts.outer, parts.inner] {
                if categoriesByPartialName[part] == nil {
                    partialNames.append(part)
                }
                categoriesByPartialName[part, default: []].append(category.name)
            }
        }

        // When two lists share a name, the earlier list wins: 戒指 is a body part before it is a
        // category.
        for slot in vocabulary.slots {
            add(slot.name, .slots([slot.name]))
        }
        for category in vocabulary.categories {
            add(category.name, .categories([category.name] + (categoriesByPartialName[category.name] ?? [])))
        }
        for job in vocabulary.jobs {
            for name in [job.abbreviation] + [job.officialName].compactMap({ $0 }) + job.nicknames {
                add(name, .jobs([job.abbreviation]))
            }
        }
        for rarity in ItemQueryVocabulary.rarities {
            add(rarity.name, .rarity(rarity.name))
            add(rarity.colour + "色", .rarity(rarity.name))
            add(rarity.colour + "裝", .rarity(rarity.name))
        }

        // Players' words the data has no name for, kept to what the data and the job filter have.
        func addEverydayNames(
            _ groups: [ItemQueryEverydayNames.Group],
            known: Set<String>,
            _ condition: ([String]) -> Condition
        ) {
            for group in groups {
                let targets = group.targets.filter { known.contains($0) }
                guard !targets.isEmpty else {
                    continue
                }
                for name in group.names {
                    add(name, condition(targets))
                }
            }
        }
        addEverydayNames(ItemQueryEverydayNames.jobGroups, known: Set(vocabulary.jobs.map(\.abbreviation)), Condition.jobs)
        addEverydayNames(ItemQueryEverydayNames.slots, known: Set(vocabulary.slots.map(\.name)), Condition.slots)
        addEverydayNames(ItemQueryEverydayNames.categories, known: Set(vocabulary.categories.map(\.name)), Condition.categories)

        for name in unbracketedNames {
            add(name.text, .categories([name.category]))
        }
        for part in partialNames {
            add(part, .categories(categoriesByPartialName[part] ?? []))
        }

        self.vocabulary = vocabulary
        self.names = names
    }

    // MARK: - Parse result

    /// Words that only join conditions into a sentence, longest first. A keyword with nothing
    /// else left once its conditions are taken out names no item.
    static let connectingWords = [
        "裝備", "道具", "東西", "那種", "搜尋", "可以", "無法", "沒有",
        "的", "能", "可", "用", "穿", "戴", "都", "跟", "和", "或", "與", "要", "給", "找", "查",
        "在", "又", "但", "賣", "買", "不", ",", "、", "､", "。", "｡"
    ]

    /// The parse result: the usage and keyword the model gave, and the conditions in the
    /// sentence. A sentence that cannot be handled keeps only its usage, and a recipe lookup only
    /// its keyword.
    func fields(for sentence: String, usage: String?, keyword: String?) -> ItemQueryFields {
        let usageLabel = usage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let usage = usageLabel.flatMap { ItemQuery.Usage(label: $0) } ?? .search
        if usage == .unsupported {
            return ItemQueryFields(usage: usageLabel)
        }

        let text = Normalized(sentence)
        var matches = self.matches(in: text)
        let keyword = self.keyword(keyword, in: text.characters, dropping: &matches)
        if usage == .recipe {
            return ItemQueryFields(usage: usageLabel, keyword: keyword)
        }
        return fields(usage: usageLabel, keyword: keyword, matches: matches)
    }

    /// The model's keyword if the sentence has it and it names an item. A keyword made of
    /// conditions (頭部裝備, 繪靈法師的筆) is dropped unless an item has exactly that name and it is
    /// more than one condition (紅蓮盾, but not 毒蛇); otherwise the conditions inside it are part
    /// of an item's name (the 盾 in 守護者之盾) and are dropped instead.
    private func keyword(_ keyword: String?, in text: [Character], dropping matches: inout [Match]) -> String? {
        guard let keyword = keyword?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        let normalizedKeyword = Array(Self.normalized(keyword))
        guard let range = Self.occurrences(of: normalizedKeyword, in: text).first else {
            return nil
        }

        var covered = Array(repeating: false, count: text.count)
        for match in matches {
            for index in match.range {
                covered[index] = true
            }
        }
        var segments: [String] = [""]
        for index in range {
            if covered[index] {
                segments.append("")
            } else {
                segments[segments.count - 1].append(text[index])
            }
        }
        let namesAnItem = segments.contains { segment in
            !Self.connectingWords.reduce(segment) { $0.replacingOccurrences(of: $1, with: "") }.isEmpty
        }
        // Compared with the names, not the matches: in 「毒蛇劍士」 the keyword 毒蛇 is no match of
        // its own, yet it is still the viper's nickname.
        let isOneConditionName = names.contains { $0.text == normalizedKeyword }
        guard namesAnItem || (!isOneConditionName && vocabulary.isItemName(keyword)) else {
            return nil
        }

        matches.removeAll { range.lowerBound <= $0.range.lowerBound && $0.range.upperBound <= range.upperBound }
        return keyword
    }

    private func fields(usage: String?, keyword: String?, matches: [Match]) -> ItemQueryFields {
        var categories: [String] = []
        var partialCategories: [[String]] = []
        var slots: [String] = []
        var jobs: [String] = []
        var rarities: [String] = []
        var equipLevel: (min: Int?, max: Int?)?
        var itemLevel: (min: Int?, max: Int?)?
        var hq: Bool?
        var tradable: Bool?

        // The first level of each kind counts. HQ and tradability are negative when any
        // mention is: 「市場板上不能買賣」 is untradable.
        for match in matches {
            switch match.condition {
            case .categories(let names) where names.count == 1:
                categories += names
            case .categories(let names):
                partialCategories.append(names)
            case .slots(let names):
                slots += names
            case .jobs(let abbreviations):
                jobs += abbreviations
            case .rarity(let name):
                rarities.append(name)
            case .equipLevel(let lower, let upper):
                equipLevel = equipLevel ?? (lower, upper)
            case .itemLevel(let lower, let upper):
                itemLevel = itemLevel ?? (lower, upper)
            case .hq(let value):
                hq = (hq ?? true) && value
            case .tradable(let value):
                tradable = (tradable ?? true) && value
            }
        }

        // 副工具 alone is every sub-tool; with 鍊金術師 in the sentence it is the alchemist's.
        let sentenceJobs = Set(jobs)
        for names in partialCategories {
            let usable = names.filter { vocabulary.isCategory(named: $0, usableByAnyOf: sentenceJobs) }
            categories += usable.isEmpty ? names : usable
        }

        func list(_ values: [String]) -> [String]? {
            var seen: Set<String> = []
            let unique = values.filter { seen.insert($0).inserted }
            return unique.isEmpty ? nil : unique
        }
        func label(_ value: Bool?, _ labels: ItemQueryVocabulary.FlagLabels) -> String? {
            value.map { $0 ? labels.yes : labels.no }
        }

        return ItemQueryFields(
            usage: usage,
            keyword: keyword,
            categories: list(categories),
            slots: list(slots),
            jobs: list(jobs),
            equipLevelMin: equipLevel?.min,
            equipLevelMax: equipLevel?.max,
            itemLevelMin: itemLevel?.min,
            itemLevelMax: itemLevel?.max,
            rarities: list(rarities),
            hq: label(hq, ItemQueryVocabulary.hqLabels),
            tradable: label(tradable, ItemQueryVocabulary.tradableLabels)
        )
    }

    // MARK: - Matching

    /// Every condition in the sentence, in the order they appear. Where two overlap the longer
    /// one wins, so 龍騎士 is not also 騎士 and 武士刀 is not also 武士.
    func matches(in sentence: String) -> [Match] {
        matches(in: Normalized(sentence))
    }

    private func matches(in text: Normalized) -> [Match] {
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

        var taken = Array(repeating: false, count: text.characters.count)
        var kept: [Match] = []
        for (_, match) in longestFirst where !match.range.contains(where: { taken[$0] }) {
            kept.append(match)
            for index in match.range {
                taken[index] = true
            }
        }
        return kept.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    private func nameMatches(in text: Normalized) -> [Match] {
        names.flatMap { name in
            Self.occurrences(of: name.text, in: text.characters)
                .filter { text.standsAlone($0) }
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

    /// Words after a number that make it a level. Players write 80等 as often as 80級; 等級 comes
    /// first, so 80等級 is read whole.
    private static let levelSuffixes = ["等級", "級", "等"]

    /// 「80級」「80等」「等級80」「Lv.80」, optionally followed by 以上, 以下 or 以內, and ranges
    /// such as 「70到80級」. A number counts only with a marker before it or a level word after it,
    /// and is always read whole, so 700 is never 70.
    private static func levelMatches(in normalized: Normalized) -> [Match] {
        let text = normalized.characters
        var matches: [Match] = []
        var index = 0
        while index < text.count {
            guard let first = number(at: index, in: normalized) else {
                index += 1
                continue
            }

            let marker = levelMarker(before: index, in: normalized)
            var end = first.end
            var saysLevel = false
            if let suffix = levelSuffix(at: end, in: text) {
                end += suffix
                saysLevel = true
            }

            var second: Int?
            if end < text.count, rangeConnectors.contains(text[end]), let next = number(at: end + 1, in: normalized) {
                second = next.value
                end = next.end
                if let suffix = levelSuffix(at: end, in: text) {
                    end += suffix
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

    /// The length of the level word right after a number, if there is one.
    private static func levelSuffix(at index: Int, in text: [Character]) -> Int? {
        levelSuffixes.first { hasWord($0, at: index, in: text) }?.count
    }

    /// The digits from `index` on, up to the first other character or whitespace.
    private static func number(at index: Int, in normalized: Normalized) -> (value: Int, end: Int)? {
        let text = normalized.characters
        var end = index
        while end < text.count, text[end].isASCII, text[end].isNumber, end == index || !normalized.spaced[end] {
            end += 1
        }
        guard end > index, let value = Int(String(text[index..<end])) else {
            return nil
        }
        return (value, end)
    }

    private static func levelMarker(before index: Int, in normalized: Normalized) -> (kind: LevelKind, start: Int)? {
        let text = normalized.characters
        var end = index
        if end > 0, levelSeparators.contains(text[end - 1]) {
            end -= 1
        }
        for marker in levelMarkers {
            let start = end - marker.text.count
            guard start >= 0, text[start..<end].elementsEqual(marker.text) else {
                continue
            }
            if normalized.joins(at: start) {
                continue
            }
            return (marker.kind, start)
        }
        return nil
    }

    // MARK: - HQ and tradability

    private static let hqWord = Array("hq")
    /// 上板 is putting an item up on the market board.
    private static let tradableWords = ["交易", "買賣", "市場板", "上板"].map { Array($0) }
    private static let negations: Set<Character> = ["不", "無", "沒", "非", "禁"]
    /// Conjunctions that end a clause as punctuation does, so the 不 in 「不能HQ但可以交易」 stays
    /// with HQ.
    private static let clauseConjunctions: Set<Character> = ["又", "但"]
    /// How far back a negation still applies, in characters: 「不可以HQ」 reaches four.
    private static let negationReach = 4

    /// 「HQ」 is a condition on HQ and 「交易」「買賣」「市場板」「上板」 one on tradability,
    /// negative when a negation comes shortly before it in the same clause.
    private static func flagMatches(in normalized: Normalized) -> [Match] {
        let text = normalized.characters
        var matches: [Match] = []
        for range in occurrences(of: hqWord, in: text) where normalized.standsAlone(range) {
            matches.append(Match(range: range, condition: .hq(!isNegated(before: range.lowerBound, in: text))))
        }
        for word in tradableWords {
            for range in occurrences(of: word, in: text) {
                matches.append(Match(range: range, condition: .tradable(!isNegated(before: range.lowerBound, in: text))))
            }
        }
        return matches
    }

    /// Punctuation and 又 or 但, so 「不要藍色的，可以交易」 is not read as 「不…交易」.
    private static func endsClause(_ character: Character) -> Bool {
        character.isPunctuation || clauseConjunctions.contains(character)
    }

    private static func isNegated(before index: Int, in text: [Character]) -> Bool {
        var position = index - 1
        var reach = 0
        while position >= 0, reach < negationReach, !endsClause(text[position]) {
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
        String(Normalized(text).characters)
    }

    /// A sentence as the matcher reads it: normalised, remembering where whitespace stood, so
    /// that 「WHM 90級」 still keeps WHM apart from 90.
    private struct Normalized {
        let characters: [Character]
        /// Whether whitespace stood right before each character.
        let spaced: [Bool]

        init(_ text: String) {
            let halfWidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
            var characters: [Character] = []
            var spaced: [Bool] = []
            var afterSpace = false
            for character in halfWidth.lowercased() {
                if character.isWhitespace {
                    afterSpace = true
                } else {
                    characters.append(character)
                    spaced.append(afterSpace)
                    afterSpace = false
                }
            }
            self.characters = characters
            self.spaced = spaced
        }

        /// Whether a Latin letter or digit runs straight into another at `index`.
        func joins(at index: Int) -> Bool {
            index > 0 && index < characters.count && !spaced[index]
                && ItemQueryMatcher.isLatinOrDigit(characters[index - 1])
                && ItemQueryMatcher.isLatinOrDigit(characters[index])
        }

        /// A match that begins or ends with a Latin letter or digit must not run into another
        /// one, so MCH is found in 「mch的火槍」 and 「MCH 80級」 but not inside a longer word.
        func standsAlone(_ range: Range<Int>) -> Bool {
            !joins(at: range.lowerBound) && !joins(at: range.upperBound)
        }
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

    private static func isLatinOrDigit(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber)
    }

    /// 「採掘工具（主工具）」 → (採掘工具, 主工具). Nil for a name without a bracketed part.
    private static func bracketedParts(of name: String) -> (outer: String, inner: String)? {
        guard name.hasSuffix("）"), let open = name.firstIndex(of: "（") else {
            return nil
        }
        let outer = String(name[..<open])
        let inner = String(name[name.index(after: open)..<name.index(before: name.endIndex)])
        guard !outer.isEmpty, !inner.isEmpty else {
            return nil
        }
        return (outer, inner)
    }
}
