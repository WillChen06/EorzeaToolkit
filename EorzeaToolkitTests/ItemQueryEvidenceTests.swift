import XCTest
@testable import EorzeaToolkit

/// In the first evaluation run the model filled fields the sentence never mentioned. Each
/// condition now carries the fragment of the sentence it rests on, and these tests pin down
/// which conditions survive (AC-16).
final class ItemQueryEvidenceTests: XCTestCase {
    private typealias Output = ItemQueryModelOutput

    func testConditionsQuotingTheSentenceAreKept() {
        let output = Output(
            usage: "搜尋",
            slots: [Output.Choice(quote: "頭部", name: "頭部")],
            jobs: [Output.Choice(quote: "白魔", name: "白魔道士")],
            hq: Output.Flag(quote: "可以HQ", value: "可HQ")
        )

        let fields = ItemQueryEvidence.fields(from: output, sentence: "80級以上白魔能穿的頭部裝備，要可以HQ的")

        XCTAssertEqual(fields.slots, ["頭部"])
        XCTAssertEqual(fields.jobs, ["白魔道士"])
        XCTAssertEqual(fields.hq, "可HQ")
    }

    func testConditionsWithoutSupportInTheSentenceAreDropped() {
        let output = Output(
            usage: "搜尋",
            categories: [Output.Choice(quote: "藥品", name: "藥品"), Output.Choice(quote: "盾", name: "盾")],
            jobs: [Output.Choice(quote: nil, name: "暗黑騎士")],
            rarities: [Output.Choice(quote: "", name: "貴重")],
            hq: Output.Flag(quote: "不可HQ", value: "不可HQ"),
            tradable: Output.Flag(quote: "可交易", value: "可交易")
        )

        let fields = ItemQueryEvidence.fields(from: output, sentence: "給騎士用的盾，90級以上")

        XCTAssertEqual(fields.categories, ["盾"])
        XCTAssertNil(fields.jobs, "no quote")
        XCTAssertNil(fields.rarities, "empty quote")
        XCTAssertNil(fields.hq)
        XCTAssertNil(fields.tradable)
        XCTAssertEqual(fields.usage, "搜尋", "usage needs no quote")
    }

    /// The first run filled 80–80 into nearly every sentence; a bound whose number is not in
    /// the quote is left unset.
    func testALevelBoundNeedsItsNumberInTheQuote() {
        let sentence = "給騎士用的盾，90級以上"

        let implied = ItemQueryEvidence.fields(
            from: Output(usage: "搜尋", equipLevel: Output.Levels(quote: "90級以上", min: 90, max: 100)),
            sentence: sentence
        )
        let copied = ItemQueryEvidence.fields(
            from: Output(usage: "搜尋", equipLevel: Output.Levels(quote: "90級以上", min: 80, max: 80)),
            sentence: sentence
        )
        let unquoted = ItemQueryEvidence.fields(
            from: Output(usage: "搜尋", itemLevel: Output.Levels(quote: "80級", min: 80, max: 80)),
            sentence: sentence
        )

        XCTAssertEqual(implied.equipLevelMin, 90)
        XCTAssertNil(implied.equipLevelMax, "100 is not in the quote")
        XCTAssertNil(copied.equipLevelMin)
        XCTAssertNil(copied.equipLevelMax)
        XCTAssertNil(unquoted.itemLevelMin, "the quote is not in the sentence")
    }

    func testTheKeywordMustAppearInTheSentence() {
        let sentence = "做剛力之寶藥要什麼材料"

        let kept = ItemQueryEvidence.fields(from: Output(usage: "查配方", keyword: "剛力之寶藥"), sentence: sentence)
        let invented = ItemQueryEvidence.fields(from: Output(usage: "查配方", keyword: "剛力之幻藥"), sentence: sentence)

        XCTAssertEqual(kept.keyword, "剛力之寶藥")
        XCTAssertNil(invented.keyword)
    }

    func testQuotesMatchIgnoringCaseWhitespaceAndWidth() {
        let output = Output(
            usage: "搜尋",
            jobs: [Output.Choice(quote: "MCH", name: "機工士")],
            equipLevel: Output.Levels(quote: "80級", min: 80, max: 80),
            itemLevel: Output.Levels(quote: "iLv600", min: 600, max: nil)
        )

        let fields = ItemQueryEvidence.fields(from: output, sentence: "mch 的火槍，８０級，iLv 600 以上")

        XCTAssertEqual(fields.jobs, ["機工士"])
        XCTAssertEqual(fields.equipLevelMin, 80)
        XCTAssertEqual(fields.itemLevelMin, 600)
    }
}
