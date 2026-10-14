import XCTest
@testable import EorzeaToolkit

/// The model answers in names; the vocabulary turns them into the ids and job abbreviations the
/// item filter uses. These tests pin that resolution down without the model, so they run on any
/// simulator.
final class ItemQueryVocabularyTests: XCTestCase {
    private func bundledVocabulary() throws -> ItemQueryVocabulary {
        let data: ItemDataResponse = try LocalDataService.load("items")
        return ItemQueryVocabulary(data: data)
    }

    // MARK: - Body parts (AC-4)

    /// 「身體」 has to cover the slots that also block other parts, or a query for body armour
    /// would miss robes and full suits.
    func testBodyPartsCoverEveryVariantOfTheirSlot() throws {
        let vocabulary = try bundledVocabulary()

        XCTAssertEqual(vocabulary.equipSlotIds(named: ["身體"]), [4, 15, 16, 19, 20, 21, 22])
        XCTAssertEqual(vocabulary.equipSlotIds(named: ["主手"]), [1, 13])
        XCTAssertEqual(vocabulary.equipSlotIds(named: ["腿部"]), [7, 18])
        XCTAssertEqual(vocabulary.equipSlotIds(named: ["頭部"]), [3])
    }

    func testBodyPartsAreTheBaseSlotsWithoutSoulCrystals() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")
        let vocabulary = ItemQueryVocabulary(data: data)

        XCTAssertEqual(
            vocabulary.slots.map(\.name),
            ["主手", "副手", "頭部", "身體", "手部", "腿部", "腳部", "耳部", "頸部", "腕部", "戒指"]
        )

        let soulCrystalIds = Set(data.equipSlots.filter { $0.nameTw == "靈魂水晶" }.map(\.id))
        let everySlotId = Set(data.equipSlots.map(\.id).filter { $0 > 0 })
        XCTAssertEqual(Set(vocabulary.slots.flatMap(\.ids)), everySlotId.subtracting(soulCrystalIds))
    }

    func testSeveralBodyPartsResolveToTheUnionOfTheirSlots() throws {
        let vocabulary = try bundledVocabulary()

        XCTAssertEqual(vocabulary.equipSlotIds(named: ["頭部", "腿部"]), [3, 7, 18])
    }

    // MARK: - Jobs (AC-5)

    func testEveryJobResolvesFromItsAbbreviationAndOfficialName() throws {
        let vocabulary = try bundledVocabulary()

        for job in vocabulary.jobs {
            XCTAssertEqual(vocabulary.jobAbbreviation(named: job.abbreviation), job.abbreviation)
            XCTAssertEqual(vocabulary.jobAbbreviation(named: job.abbreviation.lowercased()), job.abbreviation)

            let officialName = try XCTUnwrap(job.officialName, "\(job.abbreviation) has no official name")
            XCTAssertEqual(vocabulary.jobAbbreviation(named: officialName), job.abbreviation)
        }
    }

    func testDifferentNamesForAJobResolveToOneAbbreviation() throws {
        let vocabulary = try bundledVocabulary()

        XCTAssertEqual(vocabulary.jobAbbreviations(named: ["白魔", "白魔道士", "WHM", "whm"]), ["WHM"])
        XCTAssertEqual(vocabulary.jobAbbreviations(named: ["暗騎", "暗黑騎士"]), ["DRK"])
        XCTAssertEqual(vocabulary.jobAbbreviations(named: ["鍛冶", "鍛造師"]), ["BSM"])
    }

    /// Names are compared whole: several official names contain another one.
    func testJobNamesAreMatchedWhole() throws {
        let vocabulary = try bundledVocabulary()

        XCTAssertEqual(vocabulary.jobAbbreviation(named: "騎士"), "PLD")
        XCTAssertEqual(vocabulary.jobAbbreviation(named: "龍騎士"), "DRG")
        XCTAssertEqual(vocabulary.jobAbbreviation(named: "暗黑騎士"), "DRK")
        XCTAssertEqual(vocabulary.jobAbbreviation(named: "戰士"), "WAR")
        XCTAssertEqual(vocabulary.jobAbbreviation(named: "絕槍戰士"), "GNB")
        XCTAssertEqual(vocabulary.jobAbbreviation(named: "武士"), "SAM")
        XCTAssertNil(vocabulary.jobAbbreviation(named: "白"))
    }

    /// A nickname keyed by a job the filter does not offer could never be used, and a name
    /// listed under two jobs would resolve to whichever comes first.
    func testNicknamesBelongToFilterJobsAndNoNameIsShared() throws {
        let vocabulary = try bundledVocabulary()
        let filterJobs = Set(ItemJobFilterOption.displayOptions.map(\.abbreviation))

        XCTAssertTrue(Set(ItemJobNicknames.all.keys).isSubset(of: filterJobs))

        var owners: [String: String] = [:]
        for job in vocabulary.jobs {
            let names = [job.abbreviation] + [job.officialName].compactMap({ $0 }) + job.nicknames
            for name in names {
                let key = name.uppercased()
                if let owner = owners[key], owner != job.abbreviation {
                    XCTFail("\(name) names both \(owner) and \(job.abbreviation)")
                }
                owners[key] = job.abbreviation
            }
        }
    }

    // MARK: - Unknown names (AC-6)

    func testUnknownNamesAreIgnored() throws {
        let vocabulary = try bundledVocabulary()

        let query = vocabulary.resolve(ItemQueryFields(
            usage: "搜尋",
            keyword: "長袍",
            categories: ["雙手幻杖", "不存在的分類"],
            slots: ["身體", "肩膀"],
            jobs: ["WHM", "BLU", "青魔道士"],
            equipLevelMin: 80,
            rarities: ["貴重", "金色"],
            hq: "可HQ"
        ))

        XCTAssertEqual(query.usage, .search)
        XCTAssertEqual(query.keyword, "長袍")
        XCTAssertEqual(query.categoryIds, [9])
        XCTAssertEqual(query.equipSlotIds, [4, 15, 16, 19, 20, 21, 22])
        XCTAssertEqual(query.jobs, ["WHM"])
        XCTAssertEqual(query.equipLevelRange, 80...100)
        XCTAssertEqual(query.rarities, [3])
        XCTAssertEqual(query.hq, true)
    }

    func testFieldsWithOnlyUnknownValuesStayEmpty() throws {
        let vocabulary = try bundledVocabulary()

        let query = vocabulary.resolve(ItemQueryFields(
            usage: "隨便",
            categories: ["不存在的分類"],
            slots: ["肩膀"],
            jobs: ["青魔道士"],
            rarities: ["金色"],
            hq: "也許",
            tradable: "不一定"
        ))

        XCTAssertEqual(query, ItemQuery(usage: .search))
    }

    // MARK: - Lists come from the data (AC-15)

    func testCategoryAndBodyPartListsFollowTheItemData() {
        let data = ItemDataResponse(
            items: [],
            uiCategories: [
                UICategory(id: 500, nameTw: "測試分類", orderMinor: 0, orderMajor: 1),
                UICategory(id: 9, nameTw: "雙手幻杖", orderMinor: 0, orderMajor: 1)
            ],
            equipSlots: [
                EquipSlot(id: 31, nameTw: "背部（無法裝備頭部）"),
                EquipSlot(id: 3, nameTw: "頭部"),
                EquipSlot(id: 30, nameTw: "背部"),
                EquipSlot(id: 17, nameTw: "靈魂水晶")
            ]
        )

        let vocabulary = ItemQueryVocabulary(data: data)

        XCTAssertEqual(vocabulary.categories.map(\.name), ["雙手幻杖", "測試分類"])
        XCTAssertEqual(vocabulary.slots, [
            ItemQueryVocabulary.Slot(name: "頭部", ids: [3]),
            ItemQueryVocabulary.Slot(name: "背部", ids: [30, 31])
        ])
    }

    func testJobListFollowsTheItemSearchFilter() throws {
        let vocabulary = try bundledVocabulary()

        XCTAssertEqual(vocabulary.jobs.map(\.abbreviation), ItemJobFilterOption.displayOptions.map(\.abbreviation))
    }

    func testBundledDataYieldsEveryCategory() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")
        let vocabulary = ItemQueryVocabulary(data: data)

        XCTAssertEqual(vocabulary.categories.count, Set(data.uiCategories.map(\.nameTw)).count)
    }

    // MARK: - Armour and accessory categories (AC-17)

    /// 頭部防具 and 頭部 filter the same items, so a model that picks the category must not be
    /// told it is wrong.
    func testArmourAndAccessoryCategoriesBecomeTheirBodyPart() throws {
        let vocabulary = try bundledVocabulary()

        let query = vocabulary.resolve(ItemQueryFields(usage: "搜尋", categories: ["頭部防具", "耳飾", "項鍊"]))

        XCTAssertTrue(query.categoryIds.isEmpty)
        XCTAssertEqual(query.equipSlotIds, vocabulary.equipSlotIds(named: ["頭部", "耳部", "頸部"]))
    }

    func testShieldWeaponToolAndSoulCrystalCategoriesStayCategories() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")
        let vocabulary = ItemQueryVocabulary(data: data)
        let names = ["盾", "雙手劍", "鍊金工具（副工具）", "靈魂水晶"]

        let query = vocabulary.resolve(ItemQueryFields(usage: "搜尋", categories: names))

        XCTAssertEqual(query.categoryIds, vocabulary.categoryIds(named: names))
        XCTAssertTrue(query.equipSlotIds.isEmpty)
    }

    /// Which categories count as a body part comes from where their items are equipped, not
    /// from a list.
    func testBodyPartCategoriesComeFromTheItems() {
        func item(_ id: Int, category: Int, slot: Int) -> Item {
            Item(id: id, nameTw: "道具\(id)", iconId: 0, iconPath: "", ilvl: 1, rarity: 1, canBeHq: false,
                 isUntradable: false, uiCategoryId: category, equipSlot: slot)
        }
        let data = ItemDataResponse(
            items: [
                item(1, category: 500, slot: 30),
                item(2, category: 500, slot: 31),
                item(3, category: 501, slot: 3),
                item(4, category: 501, slot: 30)
            ],
            uiCategories: [
                UICategory(id: 500, nameTw: "背部防具", orderMinor: 0, orderMajor: 1),
                UICategory(id: 501, nameTw: "混合防具", orderMinor: 0, orderMajor: 1)
            ],
            equipSlots: [
                EquipSlot(id: 3, nameTw: "頭部"),
                EquipSlot(id: 30, nameTw: "背部"),
                EquipSlot(id: 31, nameTw: "背部（無法裝備頭部）")
            ]
        )
        let vocabulary = ItemQueryVocabulary(data: data)

        let backQuery = vocabulary.resolve(ItemQueryFields(usage: "搜尋", categories: ["背部防具"]))
        let mixedQuery = vocabulary.resolve(ItemQueryFields(usage: "搜尋", categories: ["混合防具"]))

        XCTAssertEqual(backQuery.equipSlotIds, [30, 31])
        XCTAssertTrue(backQuery.categoryIds.isEmpty)
        XCTAssertEqual(mixedQuery.categoryIds, [501], "items on two body parts keep the category")
    }

    // MARK: - Levels and flags

    func testLevelRangesFillTheMissingBound() {
        let bounds = ItemQuery.equipLevelBounds

        XCTAssertEqual(ItemQueryVocabulary.range(lower: 80, upper: 80, bounds: bounds), 80...80)
        XCTAssertEqual(ItemQueryVocabulary.range(lower: 80, upper: nil, bounds: bounds), 80...100)
        XCTAssertEqual(ItemQueryVocabulary.range(lower: nil, upper: 80, bounds: bounds), 1...80)
        XCTAssertEqual(ItemQueryVocabulary.range(lower: 90, upper: 80, bounds: bounds), 80...90)
        XCTAssertEqual(ItemQueryVocabulary.range(lower: 120, upper: nil, bounds: bounds), 100...100)
    }

    /// A range covering every level filters nothing, so it must compare equal to no range.
    func testRangesWithoutALimitAreNoCondition() {
        let bounds = ItemQuery.equipLevelBounds

        XCTAssertNil(ItemQueryVocabulary.range(lower: nil, upper: nil, bounds: bounds))
        XCTAssertNil(ItemQueryVocabulary.range(lower: 1, upper: 100, bounds: bounds))
        XCTAssertNil(ItemQueryVocabulary.range(lower: 1, upper: nil, bounds: bounds))
    }

    func testItemLevelBoundsMatchTheItemFilter() {
        XCTAssertEqual(ItemQuery.itemLevelBounds, ItemFilter.defaultIlvlRange)
    }

    func testFlagsReadTheirTwoLabels() {
        let labels = ItemQueryVocabulary.hqLabels

        XCTAssertEqual(ItemQueryVocabulary.flag("可HQ", labels: labels), true)
        XCTAssertEqual(ItemQueryVocabulary.flag(" 不可HQ ", labels: labels), false)
        XCTAssertNil(ItemQueryVocabulary.flag(nil, labels: labels))
        XCTAssertNil(ItemQueryVocabulary.flag("可交易", labels: labels))
    }

    func testUsageLabelsRoundTrip() {
        for usage in ItemQuery.Usage.allCases {
            XCTAssertEqual(ItemQuery.Usage(label: usage.label), usage)
        }
        XCTAssertNil(ItemQuery.Usage(label: "search"))
    }
}
