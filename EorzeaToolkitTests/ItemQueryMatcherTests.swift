import XCTest
@testable import EorzeaToolkit

/// The conditions in a sentence are matched by code, not by the model, so every rule in the
/// spec's 「程式比對」 section is pinned down here without a model.
final class ItemQueryMatcherTests: XCTestCase {
    private typealias Condition = ItemQueryMatcher.Condition

    private static let matcher: ItemQueryMatcher = {
        // Loading the item data takes a while; every test shares one matcher.
        let data: ItemDataResponse = try! LocalDataService.load("items")
        return ItemQueryMatcher(vocabulary: ItemQueryVocabulary(data: data))
    }()

    private var matcher: ItemQueryMatcher {
        Self.matcher
    }

    private func conditions(_ sentence: String) -> [Condition] {
        matcher.matches(in: sentence).map(\.condition)
    }

    private func search(_ sentence: String, keyword: String? = nil) -> ItemQueryFields {
        matcher.fields(for: sentence, usage: "搜尋", keyword: keyword)
    }

    // MARK: - Names (AC-16)

    func testFindsCategoriesBodyPartsJobsAndRarities() {
        XCTAssertEqual(conditions("龍騎的腿部裝備，紫色的"), [.job("DRG"), .slot("腿部"), .rarity("武勳")])
        XCTAssertEqual(conditions("給騎士用的盾"), [.job("PLD"), .categories(["盾"])])
        XCTAssertEqual(conditions("白魔或學者都能用的腕部裝備"), [.job("WHM"), .job("SCH"), .slot("腕部")])
    }

    /// 戒指 is both a body part and a category; as a body part it covers every ring.
    func testANameThatIsBothABodyPartAndACategoryIsTheBodyPart() {
        XCTAssertEqual(conditions("戒指"), [.slot("戒指")])
    }

    func testOverlappingNamesKeepTheLongest() {
        XCTAssertEqual(conditions("龍騎士"), [.job("DRG")])
        XCTAssertEqual(conditions("暗黑騎士"), [.job("DRK")])
        XCTAssertEqual(conditions("絕槍戰士用的槍刃"), [.job("GNB"), .categories(["槍刃"])])
        XCTAssertEqual(conditions("武士刀"), [.categories(["武士刀"])])
        XCTAssertEqual(conditions("雙手鐮刀"), [.categories(["雙手鐮刀"])])
        XCTAssertEqual(conditions("皮革師"), [.job("LTW")])
        XCTAssertEqual(conditions("皮革"), [.categories(["皮革"])])
        XCTAssertEqual(conditions("採掘工具（主工具）"), [.categories(["採掘工具（主工具）"])])
    }

    func testLatinAbbreviationsMustStandAlone() {
        XCTAssertEqual(conditions("mch的火槍"), [.job("MCH"), .categories(["火槍"])])
        XCTAssertEqual(conditions("SGE用的賢具"), [.job("SGE"), .categories(["賢具"])])
        XCTAssertEqual(conditions("給 ＷＨＭ 用"), [.job("WHM")])
        XCTAssertEqual(conditions("armor"), [])
        XCTAssertEqual(conditions("whm2"), [])
        XCTAssertEqual(conditions("2whm"), [])
        XCTAssertEqual(conditions("xmch"), [])
    }

    /// Whitespace is taken out before matching, but it still separates two Latin words.
    func testWhitespaceSeparatesLatinWords() {
        XCTAssertEqual(conditions("WHM 90級的頭部裝備"), [.job("WHM"), .equipLevel(min: 90, max: 90), .slot("頭部")])
        XCTAssertEqual(conditions("whm90級"), [.equipLevel(min: 90, max: 90)])
        XCTAssertEqual(conditions("WHM Lv.80"), [.job("WHM"), .equipLevel(min: 80, max: 80)])
        XCTAssertEqual(conditions("SGE iLv700的賢具"), [.job("SGE"), .itemLevel(min: 700, max: 700), .categories(["賢具"])])
        XCTAssertEqual(conditions("MCH HQ的火槍"), [.job("MCH"), .hq(true), .categories(["火槍"])])
    }

    func testBracketedCategoriesMatchWithoutTheirBrackets() {
        XCTAssertEqual(conditions("採掘工具主工具"), [.categories(["採掘工具（主工具）"])])
        XCTAssertEqual(conditions("魔導書學者專用"), [.categories(["魔導書（學者專用）"])])
    }

    func testAPartOfABracketedNameStandsForEveryCategoryWithIt() {
        XCTAssertEqual(conditions("採掘工具"), [.categories(["採掘工具（主工具）", "採掘工具（副工具）"])])

        guard case .categories(let subTools)? = conditions("副工具").first else {
            return XCTFail("副工具 is not a category")
        }
        XCTAssertEqual(subTools.count, 11)
        XCTAssertTrue(subTools.allSatisfy { $0.hasSuffix("（副工具）") }, "\(subTools)")

        XCTAssertEqual(conditions("魔導書"), [.categories(["魔導書", "魔導書（學者專用）"])])
        XCTAssertEqual(conditions("雜貨"), [.categories(["雜貨", "雜貨（季節活動）"])])
    }

    func testAPartialCategoryNameNarrowsToTheSentencesJobs() {
        let alchemist = search("鍊金術師的副工具")
        XCTAssertEqual(alchemist.categories, ["鍊金工具（副工具）"])
        XCTAssertEqual(alchemist.jobs, ["ALC"])

        XCTAssertEqual(search("採掘師的採掘工具").categories, ["採掘工具（主工具）", "採掘工具（副工具）"])
        XCTAssertEqual(search("學者的魔導書").categories, ["魔導書", "魔導書（學者專用）"])
        XCTAssertEqual(search("召喚的魔導書").categories, ["魔導書"])
        XCTAssertEqual(search("副工具").categories?.count, 11, "no job, no narrowing")
        XCTAssertEqual(search("白魔的副工具").categories?.count, 11, "a job that uses none keeps them all")
    }

    // MARK: - Names come from the data (AC-15)

    func testNamesComeFromTheItemData() {
        let data = ItemDataResponse(
            items: [],
            uiCategories: [UICategory(id: 500, nameTw: "測試分類", orderMinor: 0, orderMajor: 1)],
            equipSlots: [EquipSlot(id: 30, nameTw: "背部"), EquipSlot(id: 31, nameTw: "背部（無法裝備頭部）")]
        )
        let matcher = ItemQueryMatcher(vocabulary: ItemQueryVocabulary(data: data))

        XCTAssertEqual(matcher.matches(in: "背部的測試分類").map(\.condition), [.slot("背部"), .categories(["測試分類"])])
    }

    // MARK: - Armour and accessory categories (AC-17)

    func testArmourAndAccessoryCategoriesResolveToTheirBodyPart() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")
        let vocabulary = ItemQueryVocabulary(data: data)

        let query = vocabulary.resolve(search("詩人能戴的耳飾和綠色項鍊"))

        XCTAssertTrue(query.categoryIds.isEmpty)
        XCTAssertEqual(query.equipSlotIds, vocabulary.equipSlotIds(named: ["耳部", "頸部"]))
        XCTAssertEqual(vocabulary.resolve(search("騎士的盾")).categoryIds, vocabulary.categoryIds(named: ["盾"]))
    }

    // MARK: - Levels (AC-19)

    func testEquipLevelsInEveryForm() {
        let cases: [(String, Condition)] = [
            ("90級的頭部裝備", .equipLevel(min: 90, max: 90)),
            ("80級以上", .equipLevel(min: 80, max: nil)),
            ("50級以下", .equipLevel(min: nil, max: 50)),
            ("60級以內", .equipLevel(min: nil, max: 60)),
            ("等級 80", .equipLevel(min: 80, max: 80)),
            ("等級90到100", .equipLevel(min: 90, max: 100)),
            ("70至80級", .equipLevel(min: 70, max: 80)),
            ("70到80級", .equipLevel(min: 70, max: 80)),
            ("70級~80級", .equipLevel(min: 70, max: 80)),
            ("等級 90-100", .equipLevel(min: 90, max: 100)),
            ("Lv.80的刺劍", .equipLevel(min: 80, max: 80)),
            ("lv80", .equipLevel(min: 80, max: 80)),
            ("８０級", .equipLevel(min: 80, max: 80))
        ]

        for (sentence, expected) in cases {
            XCTAssertEqual(conditions(sentence).first, expected, sentence)
        }
    }

    func testItemLevelsNeedAnItemLevelWord() {
        let cases: [(String, Condition)] = [
            ("品級700以上", .itemLevel(min: 700, max: nil)),
            ("iLv 600到650", .itemLevel(min: 600, max: 650)),
            ("ILVL600", .itemLevel(min: 600, max: 600)),
            ("裝等700的雙手劍", .itemLevel(min: 700, max: 700)),
            ("品級690以下", .itemLevel(min: nil, max: 690))
        ]

        for (sentence, expected) in cases {
            XCTAssertEqual(conditions(sentence).first, expected, sentence)
        }
    }

    /// The second run kept 70 from 「700」 because 70 is part of the text; numbers are read whole.
    func testNumbersAreReadWhole() {
        XCTAssertEqual(conditions("品級700"), [.itemLevel(min: 700, max: 700)])
        XCTAssertEqual(conditions("100級"), [.equipLevel(min: 100, max: 100)])
        XCTAssertEqual(conditions("等級 90 100"), [.equipLevel(min: 90, max: 90)], "a space ends a number")
        XCTAssertEqual(conditions("Lv80 2個"), [.equipLevel(min: 80, max: 80)], "a space ends a number")
    }

    func testNumbersWithoutALevelWordAreNoLevel() {
        XCTAssertEqual(conditions("700的雙手劍"), [.categories(["雙手劍"])])
        XCTAssertEqual(conditions("給我3個藥品"), [.categories(["藥品"])])
        XCTAssertEqual(conditions("90-100"), [])
        XCTAssertEqual(conditions("xlv80"), [])
    }

    func testTheFirstLevelOfEachKindCounts() {
        let fields = search("90級以上，品級600以上，100級，品級700")

        XCTAssertEqual(fields.equipLevelMin, 90)
        XCTAssertNil(fields.equipLevelMax)
        XCTAssertEqual(fields.itemLevelMin, 600)
        XCTAssertNil(fields.itemLevelMax)
    }

    // MARK: - Rarities, HQ and tradability (AC-20)

    func testRaritiesByNameOrColour() {
        XCTAssertEqual(conditions("紫色"), [.rarity("武勳")])
        XCTAssertEqual(conditions("綠裝"), [.rarity("稀有")])
        XCTAssertEqual(conditions("藍色的"), [.rarity("貴重")])
        XCTAssertEqual(conditions("粉色"), [.rarity("紅蓮")])
        XCTAssertEqual(conditions("白色"), [.rarity("一般")])
        XCTAssertEqual(conditions("貴重"), [.rarity("貴重")])
        XCTAssertEqual(conditions("白魔"), [.job("WHM")], "a colour alone is no rarity")
    }

    func testHQIsPositiveUnlessNegated() {
        XCTAssertEqual(conditions("要可以HQ的"), [.hq(true)])
        XCTAssertEqual(conditions("可HQ"), [.hq(true)])
        XCTAssertEqual(conditions("不能HQ"), [.hq(false)])
        XCTAssertEqual(conditions("不可以 hq"), [.hq(false)])
        XCTAssertEqual(conditions("無法HQ"), [.hq(false)])
        XCTAssertEqual(conditions("沒有HQ"), [.hq(false)])
        XCTAssertEqual(conditions("非HQ"), [.hq(false)])
        XCTAssertEqual(conditions("HQs"), [], "HQ must stand alone")
    }

    func testTradabilityIsPositiveUnlessNegated() {
        XCTAssertEqual(conditions("可以交易"), [.tradable(true)])
        XCTAssertEqual(conditions("能在市場板賣"), [.tradable(true)])
        XCTAssertEqual(conditions("不能交易的那種"), [.tradable(false)])
        XCTAssertEqual(conditions("不能在市場板賣"), [.tradable(false)])
        XCTAssertEqual(conditions("不能買賣"), [.tradable(false)])
        XCTAssertEqual(conditions("禁止交易"), [.tradable(false)])
        XCTAssertEqual(conditions("沒辦法交易"), [.tradable(false)])
    }

    /// A negation belongs to its own clause and reaches four characters back.
    func testNegationsStayInTheirClause() {
        XCTAssertEqual(conditions("可以HQ又不能交易"), [.hq(true), .tradable(false)])
        XCTAssertEqual(conditions("不能HQ但可以交易"), [.hq(false), .tradable(true)])
        XCTAssertEqual(conditions("不要藍色的，可以交易"), [.rarity("貴重"), .tradable(true)])
        XCTAssertEqual(conditions("不是說好的可以交易"), [.tradable(true)])
        XCTAssertEqual(conditions("不：可以交易"), [.tradable(true)], "any punctuation ends a clause")
        XCTAssertEqual(conditions("不/可以HQ"), [.hq(true)], "any punctuation ends a clause")
    }

    func testFlagsBecomeTheirLabels() {
        let fields = search("可以HQ又能在市場板賣的藥品")

        XCTAssertEqual(fields.hq, "可HQ")
        XCTAssertEqual(fields.tradable, "可交易")
        XCTAssertEqual(search("不能HQ，不能交易").hq, "不可HQ")
        XCTAssertEqual(search("不能HQ，不能交易").tradable, "不可交易")
    }

    func testANegatedMentionDecides() {
        XCTAssertEqual(conditions("市場板上不能買賣"), [.tradable(true), .tradable(false)])
        XCTAssertEqual(search("市場板上不能買賣").tradable, "不可交易")
        XCTAssertEqual(search("HQ的，不能HQ").hq, "不可HQ")
        XCTAssertEqual(search("可以在市場板買賣").tradable, "可交易")
    }

    // MARK: - Keywords (AC-18)

    func testAKeywordNotInTheSentenceIsDropped() {
        XCTAssertNil(search("白魔穿的身體裝備", keyword: "長袍").keyword)
        XCTAssertNil(search("白魔穿的身體裝備", keyword: " ").keyword)
    }

    /// The second run returned keywords such as these; as a name filter they would hide almost
    /// every result. The conditions in them still count.
    func testAKeywordMadeOfConditionsIsDropped() {
        let cases: [(sentence: String, keyword: String)] = [
            ("90級的頭部裝備", "頭部裝備"),
            ("90級的頭部裝備", "頭部"),
            ("繪靈法師的筆，不能交易的那種", "繪靈法師的筆"),
            ("粉色的身體裝備，不能交易", "粉色的身體裝備"),
            ("鍊金術師的副工具", "鍊金術師的副工具"),
            ("暗騎可以穿的100級身體裝備", "暗騎可以穿的100級身體裝備"),
            ("SGE用的賢具", "SGE"),
            ("可以HQ又能在市場板賣的藥品", "可以HQ又能在市場板賣的藥品")
        ]

        for (sentence, keyword) in cases {
            let fields = search(sentence, keyword: keyword)
            XCTAssertNil(fields.keyword, keyword)
            XCTAssertEqual(fields, search(sentence), keyword)
        }
    }

    /// Both parts of 紅蓮盾 and 騎士盾 are conditions, yet each is an item's full name.
    func testAKeywordThatIsAnItemsNameIsKept() {
        XCTAssertEqual(
            matcher.fields(for: "紅蓮盾怎麼做", usage: "查配方", keyword: "紅蓮盾"),
            ItemQueryFields(usage: "查配方", keyword: "紅蓮盾")
        )
        XCTAssertEqual(search("找騎士盾", keyword: "騎士盾"), ItemQueryFields(usage: "搜尋", keyword: "騎士盾"))
    }

    /// 毒蛇 is an item, but also the viper's nickname; a single condition stays a condition.
    func testAnItemNamedLikeOneConditionIsTheCondition() {
        let fields = search("毒蛇能穿的頭部裝備", keyword: "毒蛇")

        XCTAssertNil(fields.keyword)
        XCTAssertEqual(fields.jobs, ["VPR"])
        XCTAssertNil(search("天球儀", keyword: "天球儀").keyword)

        let insideALongerName = search("毒蛇劍士的頭部裝備", keyword: "毒蛇")
        XCTAssertNil(insideALongerName.keyword)
        XCTAssertEqual(insideALongerName.jobs, ["VPR"])
    }

    func testConditionsInsideAnItemNameAreNotConditions() {
        let fields = search("找守護者之盾，90級以上", keyword: "守護者之盾")

        XCTAssertEqual(fields.keyword, "守護者之盾")
        XCTAssertNil(fields.categories)
        XCTAssertEqual(fields.equipLevelMin, 90)
    }

    /// Only conditions wholly inside the keyword are part of the name; one the keyword cuts into
    /// still counts.
    func testAConditionPartlyInsideTheKeywordStillCounts() {
        let fields = search("白魔道士長袍", keyword: "道士長袍")

        XCTAssertEqual(fields.keyword, "道士長袍")
        XCTAssertEqual(fields.jobs, ["WHM"])
    }

    func testAnItemNameKeywordKeepsTheOtherConditions() {
        let fields = search("白魔穿的身體裝備，名字裡有長袍", keyword: "長袍")

        XCTAssertEqual(fields, ItemQueryFields(usage: "搜尋", keyword: "長袍", slots: ["身體"], jobs: ["WHM"]))
    }

    func testKeywordsAreComparedNormalised() {
        XCTAssertEqual(search("找ＡＢＣ長袍", keyword: " abc長袍 ").keyword, "abc長袍")
    }

    // MARK: - Usage (AC-21)

    func testASentenceThatCannotBeHandledKeepsOnlyItsUsage() {
        let fields = matcher.fields(for: "可以交易的頭部裝備，最好是紫色", usage: "無法處理", keyword: "頭部")

        XCTAssertEqual(fields, ItemQueryFields(usage: "無法處理"))
    }

    func testARecipeLookupKeepsOnlyItsKeyword() {
        let fields = matcher.fields(for: "90級的白鋼錠怎麼做，要可以HQ", usage: "查配方", keyword: "白鋼錠")

        XCTAssertEqual(fields, ItemQueryFields(usage: "查配方", keyword: "白鋼錠"))
    }

    func testAnUnknownUsageIsASearch() {
        let fields = matcher.fields(for: "90級的頭部裝備", usage: "隨便", keyword: nil)

        XCTAssertEqual(fields, ItemQueryFields(usage: "隨便", slots: ["頭部"], equipLevelMin: 90, equipLevelMax: 90))
    }

    // MARK: - Whole sentences

    func testAWholeSentence() {
        XCTAssertEqual(
            search("80級以上白魔能穿的頭部裝備，要可以HQ的"),
            ItemQueryFields(usage: "搜尋", slots: ["頭部"], jobs: ["WHM"], equipLevelMin: 80, hq: "可HQ")
        )
        XCTAssertEqual(
            search("召喚能戴的戒指，iLv 600到650"),
            ItemQueryFields(usage: "搜尋", slots: ["戒指"], jobs: ["SMN"], itemLevelMin: 600, itemLevelMax: 650)
        )
    }
}
