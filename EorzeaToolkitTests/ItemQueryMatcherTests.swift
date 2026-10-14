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

    // MARK: - Rarities (AC-20)

    func testRaritiesByNameOrColour() {
        XCTAssertEqual(conditions("紫色"), [.rarity("武勳")])
        XCTAssertEqual(conditions("綠裝"), [.rarity("稀有")])
        XCTAssertEqual(conditions("藍色的"), [.rarity("貴重")])
        XCTAssertEqual(conditions("粉色"), [.rarity("紅蓮")])
        XCTAssertEqual(conditions("白色"), [.rarity("一般")])
        XCTAssertEqual(conditions("貴重"), [.rarity("貴重")])
        XCTAssertEqual(conditions("白魔"), [.job("WHM")], "a colour alone is no rarity")
    }
}
