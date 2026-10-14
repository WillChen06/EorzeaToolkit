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

        XCTAssertEqual(conditions("魔導書"), [.categories(["魔導書"])], "a category's own name is not a partial name")
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

    // MARK: - Levels (AC-19)

    func testEquipLevelsInEveryForm() {
        let cases: [(String, Condition)] = [
            ("90級的頭部裝備", .equipLevel(min: 90, max: 90)),
            ("80級以上", .equipLevel(min: 80, max: nil)),
            ("50級以下", .equipLevel(min: nil, max: 50)),
            ("60級以內", .equipLevel(min: nil, max: 60)),
            ("等級90到100", .equipLevel(min: 90, max: 100)),
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
    }

    func testNumbersWithoutALevelWordAreNoLevel() {
        XCTAssertEqual(conditions("700的雙手劍"), [.categories(["雙手劍"])])
        XCTAssertEqual(conditions("給我3個藥品"), [.categories(["藥品"])])
        XCTAssertEqual(conditions("90-100"), [])
        XCTAssertEqual(conditions("xlv80"), [])
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
        XCTAssertEqual(conditions("HQs"), [], "HQ must stand alone")
    }

    func testTradabilityIsPositiveUnlessNegated() {
        XCTAssertEqual(conditions("可以交易"), [.tradable(true)])
        XCTAssertEqual(conditions("能在市場板賣"), [.tradable(true)])
        XCTAssertEqual(conditions("不能交易的那種"), [.tradable(false)])
        XCTAssertEqual(conditions("不能在市場板賣"), [.tradable(false)])
        XCTAssertEqual(conditions("不能買賣"), [.tradable(false)])
        XCTAssertEqual(conditions("禁止交易"), [.tradable(false)])
    }

    /// A negation belongs to its own clause and reaches four characters back.
    func testNegationsStayInTheirClause() {
        XCTAssertEqual(conditions("可以HQ又不能交易"), [.hq(true), .tradable(false)])
        XCTAssertEqual(conditions("不能HQ但可以交易"), [.hq(false), .tradable(true)])
        XCTAssertEqual(conditions("不要藍色的，可以交易"), [.rarity("貴重"), .tradable(true)])
        XCTAssertEqual(conditions("不是說好的可以交易"), [.tradable(true)])
    }
}
