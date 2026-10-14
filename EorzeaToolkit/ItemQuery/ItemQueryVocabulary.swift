import Foundation

/// The names the matcher looks for in a sentence, and the lookup that turns them into the ids and
/// job abbreviations the item filter uses.
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

    /// Body parts that hold weapons, tools and shields. Their categories stay categories, since
    /// a category such as 雙手劍 says more than 主手 does.
    static let handSlotNames: Set<String> = ["主手", "副手"]

    /// In id order.
    let categories: [Category]
    /// In the base slot's id order.
    let slots: [Slot]
    /// In the item search filter's order.
    let jobs: [Job]

    private let categoryIdsByName: [String: [Int]]
    private let slotIdsByName: [String: [Int]]
    /// Armour and accessory categories (頭部防具, 耳飾 …) and the body part their items go on.
    private let bodyPartByCategoryId: [Int: String]
    /// The filter jobs that can use at least one item in each category.
    private let jobsByCategoryId: [Int: Set<String>]
    private let jobAbbreviationsByName: [String: String]
    private let rarityIdsByName: [String: Int]
    private let itemNames: Set<String>

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

        // A category stands for a body part when every equippable item in it goes on that one
        // part, and the part is not a hand.
        var bodyPartNameBySlotId: [Int: String] = [:]
        for slot in slots {
            for id in slot.ids where bodyPartNameBySlotId[id] == nil {
                bodyPartNameBySlotId[id] = slot.name
            }
        }
        var bodyPartsByCategoryId: [Int: Set<String>] = [:]
        var categoriesOffBodyParts: Set<Int> = []
        for item in data.items where item.equipSlot > 0 {
            if let part = bodyPartNameBySlotId[item.equipSlot] {
                bodyPartsByCategoryId[item.uiCategoryId, default: []].insert(part)
            } else {
                categoriesOffBodyParts.insert(item.uiCategoryId)
            }
        }
        var bodyPartByCategoryId: [Int: String] = [:]
        for (categoryId, parts) in bodyPartsByCategoryId where parts.count == 1 {
            guard let part = parts.first,
                  !Self.handSlotNames.contains(part),
                  !categoriesOffBodyParts.contains(categoryId) else {
                continue
            }
            bodyPartByCategoryId[categoryId] = part
        }

        let filterJobs = Set(jobOptions.map(\.abbreviation))
        var filterJobsByClassJobCategoryId: [Int: Set<String>] = [:]
        for category in data.classjobCategories {
            filterJobsByClassJobCategoryId[category.id] = filterJobs.intersection(category.jobs)
        }
        var jobsByCategoryId: [Int: Set<String>] = [:]
        for item in data.items {
            guard let jobs = filterJobsByClassJobCategoryId[item.classjobCategoryId], !jobs.isEmpty else {
                continue
            }
            jobsByCategoryId[item.uiCategoryId, default: []].formUnion(jobs)
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
        self.bodyPartByCategoryId = bodyPartByCategoryId
        self.jobsByCategoryId = jobsByCategoryId
        self.jobAbbreviationsByName = jobAbbreviationsByName
        self.rarityIdsByName = rarityIdsByName
        self.itemNames = Set(data.items.map { Self.trimmed($0.nameTw) })
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

    /// Whether some item is called exactly this. 紅蓮盾 is an item even though both its parts
    /// are conditions. Names are compared as written: normalising every item name would cost more
    /// than the rare full-width name is worth.
    func isItemName(_ name: String) -> Bool {
        itemNames.contains(Self.trimmed(name))
    }

    func rarityIds(named names: [String]) -> Set<Int> {
        Set(names.compactMap { rarityIdsByName[Self.trimmed($0)] })
    }

    /// Whether one of the jobs can use an item in the named category, judged from the items'
    /// job categories. 鍊金工具（副工具） is usable by ALC and no other job.
    func isCategory(named name: String, usableByAnyOf jobs: Set<String>) -> Bool {
        (categoryIdsByName[Self.trimmed(name)] ?? []).contains { id in
            !(jobsByCategoryId[id] ?? []).isDisjoint(with: jobs)
        }
    }

    // MARK: - Resolution

    /// Resolves names to ids. Unknown names are dropped, armour and accessory categories become
    /// their body part, a missing level bound takes the bound of the range, and a range covering
    /// every level is no condition at all. The keyword is only trimmed: `ItemQueryMatcher`
    /// already checked it against the sentence.
    func resolve(_ fields: ItemQueryFields) -> ItemQuery {
        let namedCategoryIds = categoryIds(named: fields.categories ?? [])
        let bodyPartCategoryIds = namedCategoryIds.filter { bodyPartByCategoryId[$0] != nil }
        let bodyPartNames = bodyPartCategoryIds.sorted().compactMap { bodyPartByCategoryId[$0] }

        return ItemQuery(
            usage: fields.usage.flatMap { ItemQuery.Usage(label: Self.trimmed($0)) } ?? .search,
            keyword: fields.keyword.map(Self.trimmed).flatMap { $0.isEmpty ? nil : $0 },
            categoryIds: namedCategoryIds.subtracting(bodyPartCategoryIds),
            equipSlotIds: equipSlotIds(named: (fields.slots ?? []) + bodyPartNames),
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
