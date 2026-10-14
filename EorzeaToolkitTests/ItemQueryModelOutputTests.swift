import XCTest
@testable import EorzeaToolkit

/// The model answers in plain text, so how that text is read is pinned down here (AC-22).
final class ItemQueryModelOutputTests: XCTestCase {
    private typealias Output = ItemQueryModelOutput

    func testReadsBothFields() {
        XCTAssertEqual(Output(text: "用法：搜尋\n關鍵字：歐米茄"), Output(usage: "搜尋", keyword: "歐米茄"))
        XCTAssertEqual(Output(text: "用法：查配方\n關鍵字：高級強心劑"), Output(usage: "查配方", keyword: "高級強心劑"))
    }

    func testAMissingKeywordLineMeansNoKeyword() {
        XCTAssertEqual(Output(text: "用法：無法處理"), Output(usage: "無法處理"))
    }

    func testAnEmptyOrNoneKeywordMeansNoKeyword() {
        for text in ["用法：搜尋\n關鍵字：", "用法：搜尋\n關鍵字：無", "用法：搜尋\n關鍵字： 沒有 "] {
            XCTAssertEqual(Output(text: text), Output(usage: "搜尋"), text)
        }
    }

    func testColonsWhitespaceQuotesAndMarkdownAreTolerated() {
        let expected = Output(usage: "搜尋", keyword: "歐米茄")

        for text in [
            "用法: 搜尋\n關鍵字: 歐米茄",
            "  用法 ： 搜尋  \r\n 關鍵字：「歐米茄」",
            "- **用法**：\"搜尋\"\n- **關鍵字**：『歐米茄』",
            "好的。\n用法：搜尋\n關鍵字：歐米茄\n用法：查配方"
        ] {
            XCTAssertEqual(Output(text: text), expected, text)
        }
    }

    /// A refusal message has no usage line, so it is unreadable rather than a search.
    func testAnAnswerWithoutAKnownUsageIsUnreadable() {
        XCTAssertNil(Output(text: "關鍵字：歐米茄"))
        XCTAssertNil(Output(text: "用法：搜尋道具"))
        XCTAssertNil(Output(text: "抱歉，我無法回答這個問題。"))
        XCTAssertNil(Output(text: ""))
    }

    func testTextIsTheFormatItIsReadIn() {
        XCTAssertEqual(Output(usage: "搜尋", keyword: "歐米茄").text, "用法：搜尋\n關鍵字：歐米茄")
        XCTAssertEqual(Output(usage: "無法處理").text, "用法：無法處理")

        for output in [Output(usage: "搜尋", keyword: "歐米茄"), Output(usage: "無法處理")] {
            XCTAssertEqual(Output(text: output.text), output)
        }
    }
}
