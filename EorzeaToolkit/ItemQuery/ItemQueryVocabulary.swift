import Foundation

/// The names the model may choose from, and the lookup that turns them back into the ids and job
/// abbreviations the item filter uses.
///
/// Categories and equip slots come from the item data and jobs from the item search filter's
/// job list, so a category, slot or job added to the data needs no change here. Names that are
/// not in these lists resolve to nothing instead of failing.
struct ItemQueryVocabulary: Sendable {
    struct Category: Equatable, Sendable {
        let name: String
        let ids: [Int]
    }

    /// A body part: a base equip slot together with its 「（無法裝備…）」 variants.
    struct Slot: Equatable, Sendable {
        let name: String
        let ids: [Int]
    }

    struct Job: Equatable, Sendable {
        let abbreviation: String
        /// The official Traditional Chinese name from items.json, if the data has one.
        let officialName: String?
        let nicknames: [String]

        /// The value the model picks for this job.
        var choice: String {
            officialName ?? abbreviation
        }
    }

    struct Rarity: Equatable, Sendable {
        let id: Int
        let name: String
        let colour: String
    }

    struct FlagLabels: Equatable, Sendable {
        let yes: String
        let no: String
    }

    /// The rarities the item filter offers, with the colour players call them by.
    static let rarities: [Rarity] = [
        Rarity(id: 1, name: "一般", colour: "白"),
        Rarity(id: 2, name: "稀有", colour: "綠"),
        Rarity(id: 3, name: "貴重", colour: "藍"),
        Rarity(id: 4, name: "武勳", colour: "紫"),
        Rarity(id: 7, name: "紅蓮", colour: "粉")
    ]

    static let hqLabels = FlagLabels(yes: "可HQ", no: "不可HQ")
    static let tradableLabels = FlagLabels(yes: "可交易", no: "不可交易")

    /// Base equip slots that are not body parts. Soul crystals are searched by category.
    static let excludedSlotNames: Set<String> = ["靈魂水晶"]

    /// In id order.
    let categories: [Category]
    /// In the base slot's id order.
    let slots: [Slot]
    /// In the item search filter's order.
    let jobs: [Job]

    private let categoryIdsByName: [String: [Int]]
    private let slotIdsByName: [String: [Int]]
    private let jobAbbreviationsByName: [String: String]
    private let rarityIdsByName: [String: Int]

    init(
        data: ItemDataResponse,
        jobOptions: [ItemJobFilterOption] = ItemJobFilterOption.displayOptions,
        nicknames: [String: [String]] = ItemJobNicknames.all
    ) {
        var categoryNames: [String] = []
        var categoryIdsByName: [String: [Int]] = [:]
        for category in data.uiCategories.sorted(by: { $0.id < $1.id }) {
            let name = Self.trimmed(category.nameTw)
            guard category.id > 0, !name.isEmpty else {
                continue
            }
            if categoryIdsByName[name] == nil {
                categoryNames.append(name)
            }
            categoryIdsByName[name, default: []].append(category.id)
        }

        let equipSlots = data.equipSlots
            .filter { $0.id > 0 && !Self.trimmed($0.nameTw).isEmpty }
            .sorted { $0.id < $1.id }
        let baseSlots = equipSlots.filter { slot in
            let name = Self.trimmed(slot.nameTw)
            return !name.contains("（") && !Self.excludedSlotNames.contains(name)
        }
        let slots = baseSlots.map { base -> Slot in
            let baseName = Self.trimmed(base.nameTw)
            let ids = equipSlots
                .filter { slot in
                    let name = Self.trimmed(slot.nameTw)
                    return name == baseName || name.hasPrefix(baseName + "（")
                }
                .map(\.id)
            return Slot(name: baseName, ids: ids)
        }

        var officialNames: [String: String] = [:]
        for category in data.classjobCategories.sorted(by: { $0.id < $1.id }) where category.jobs.count == 1 {
            let name = Self.trimmed(category.nameTw)
            if !name.isEmpty, officialNames[category.jobs[0]] == nil {
                officialNames[category.jobs[0]] = name
            }
        }
        let jobs = jobOptions.map { option in
            Job(
                abbreviation: option.abbreviation,
                officialName: officialNames[option.abbreviation],
                nicknames: nicknames[option.abbreviation] ?? []
            )
        }

        var jobAbbreviationsByName: [String: String] = [:]
        for job in jobs {
            let names = [job.abbreviation] + [job.officialName].compactMap({ $0 }) + job.nicknames
            for name in names {
                let key = Self.jobKey(name)
                if jobAbbreviationsByName[key] == nil {
                    jobAbbreviationsByName[key] = job.abbreviation
                }
            }
        }

        var rarityIdsByName: [String: Int] = [:]
        for rarity in Self.rarities {
            rarityIdsByName[rarity.name] = rarity.id
        }

        self.categories = categoryNames.map { Category(name: $0, ids: categoryIdsByName[$0] ?? []) }
        self.slots = slots
        self.jobs = jobs
        self.categoryIdsByName = categoryIdsByName
        self.slotIdsByName = Dictionary(slots.map { ($0.name, $0.ids) }, uniquingKeysWith: { first, _ in first })
        self.jobAbbreviationsByName = jobAbbreviationsByName
        self.rarityIdsByName = rarityIdsByName
    }

    // MARK: - Lookup

    func categoryIds(named names: [String]) -> Set<Int> {
        Set(names.flatMap { categoryIdsByName[Self.trimmed($0)] ?? [] })
    }

    func equipSlotIds(named names: [String]) -> Set<Int> {
        Set(names.flatMap { slotIdsByName[Self.trimmed($0)] ?? [] })
    }

    /// Matches a whole name — abbreviation (any case), official name or nickname — never a part
    /// of one, so 騎士 does not match 龍騎士.
    func jobAbbreviation(named name: String) -> String? {
        jobAbbreviationsByName[Self.jobKey(name)]
    }

    func jobAbbreviations(named names: [String]) -> Set<String> {
        Set(names.compactMap { jobAbbreviation(named: $0) })
    }

    func rarityIds(named names: [String]) -> Set<Int> {
        Set(names.compactMap { rarityIdsByName[Self.trimmed($0)] })
    }

    // MARK: - Resolution

    /// Resolves names to ids. Unknown names are dropped, a missing level bound takes the bound
    /// of the range, and a range covering every level is no condition at all.
    func resolve(_ fields: ItemQueryFields) -> ItemQuery {
        ItemQuery(
            usage: fields.usage.flatMap { ItemQuery.Usage(label: Self.trimmed($0)) } ?? .search,
            keyword: Self.keyword(fields.keyword),
            categoryIds: categoryIds(named: fields.categories ?? []),
            equipSlotIds: equipSlotIds(named: fields.slots ?? []),
            jobs: jobAbbreviations(named: fields.jobs ?? []),
            equipLevelRange: Self.range(
                lower: fields.equipLevelMin,
                upper: fields.equipLevelMax,
                bounds: ItemQuery.equipLevelBounds
            ),
            itemLevelRange: Self.range(
                lower: fields.itemLevelMin,
                upper: fields.itemLevelMax,
                bounds: ItemQuery.itemLevelBounds
            ),
            rarities: rarityIds(named: fields.rarities ?? []),
            hq: Self.flag(fields.hq, labels: Self.hqLabels),
            tradable: Self.flag(fields.tradable, labels: Self.tradableLabels)
        )
    }

    static func range(lower: Int?, upper: Int?, bounds: ClosedRange<Int>) -> ClosedRange<Int>? {
        guard lower != nil || upper != nil else {
            return nil
        }

        let from = clamp(lower ?? bounds.lowerBound, to: bounds)
        let to = clamp(upper ?? bounds.upperBound, to: bounds)
        let range = Swift.min(from, to)...Swift.max(from, to)
        return range == bounds ? nil : range
    }

    static func flag(_ label: String?, labels: FlagLabels) -> Bool? {
        guard let label = label.map(trimmed) else {
            return nil
        }
        if label == labels.yes {
            return true
        }
        if label == labels.no {
            return false
        }
        return nil
    }

    private static func keyword(_ value: String?) -> String? {
        guard let value = value.map(trimmed), !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func clamp(_ value: Int, to bounds: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(value, bounds.lowerBound), bounds.upperBound)
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func jobKey(_ value: String) -> String {
        trimmed(value).uppercased()
    }
}
