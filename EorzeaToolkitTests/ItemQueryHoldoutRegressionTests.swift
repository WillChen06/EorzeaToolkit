import XCTest
@testable import EorzeaToolkit

/// The first held-out run replayed through the matching rules: the model's answers from that run,
/// read and matched again, against the expected results the user confirmed in holdout-1.json.
/// The rules were adjusted to these sentences, so they guard against going back (AC-34).
final class ItemQueryHoldoutRegressionTests: XCTestCase {
    private struct HoldoutFile: Decodable {
        struct Case: Decodable {
            let id: String
            let query: String
            let expected: ItemQueryFields
        }

        let cases: [Case]
    }

    /// Sentences the rules do not cover in this phase (prompts/item-description-search.md).
    private static let knownMisses: [String: String] = [
        "holdout-02": "爆發藥 is players' name for 寶藥; such nicknames are left for later",
        "holdout-g04": "副工具 is a category, which selects the same items as the 副手 body part"
    ]

    /// The model's answer to each sentence in the first run, as docs/foundation-models-eval.md
    /// records it, with each 「 / 」 back on its own line.
    ///
    /// The report prints answers only for the sentences it got wrong. The five it got right are
    /// rebuilt from their expected results, which loses nothing: a recipe lookup keeps only its
    /// keyword as the model gave it, and a sentence that cannot be handled keeps only its usage.
    private static let answers: [String: String] = [
        "holdout-01": "用法：查配方\n關鍵字：多瑪茶", // rebuilt
        "holdout-02": "用法：查配方\n關鍵字：爆發藥",
        "holdout-03": "用法：搜尋\n關鍵字：坦",
        "holdout-04": "用法：搜尋",
        "holdout-05": "用法：搜尋",
        "holdout-06": "用法：搜尋\n關鍵字：遠敏",
        "holdout-07": "用法：搜尋",
        "holdout-08": "用法：搜尋\n關鍵字：吟遊、身體裝備",
        "holdout-g01": "用法：搜尋\n關鍵字：暗騎",
        "holdout-g02": "用法：搜尋\n關鍵字：白魔的杖",
        "holdout-g03": "用法：搜尋\n關鍵字：坦能",
        "holdout-g04": "用法：搜尋\n關鍵字：採集職的副工具",
        "holdout-g05": "用法：搜尋\n關鍵字：手套",
        "holdout-g07": "用法：搜尋\n關鍵字：武士的刀",
        "holdout-g08": "用法：搜尋\n關鍵字：毒蛇的二刀",
        "holdout-g09": "用法：搜尋\n關鍵字：伊甸的戒指",
        "holdout-g10": "用法：搜尋\n關鍵字：寄葉的衣服",
        "holdout-g12": "用法：搜尋\n關鍵字：弓",
        "holdout-g13": "用法：搜尋\n關鍵字：鞋子",
        "holdout-g14": "用法：搜尋\n關鍵字：食物",
        "holdout-g15": "用法：查配方\n關鍵字：羅蘭莓派", // rebuilt
        "holdout-g16": "用法：查配方\n關鍵字：鐵刀木角材", // rebuilt
        "holdout-g17": "用法：無法處理", // rebuilt
        "holdout-g18": "用法：無法處理" // rebuilt
    ]

    private static let vocabulary: ItemQueryVocabulary = {
        let data: ItemDataResponse = try! LocalDataService.load("items")
        return ItemQueryVocabulary(data: data)
    }()

    private static let matcher = ItemQueryMatcher(vocabulary: vocabulary)

    func testEverySentenceHasItsAnswer() throws {
        let cases = try Self.cases()

        XCTAssertEqual(cases.count, 24)
        XCTAssertEqual(Set(cases.map(\.id)), Set(Self.answers.keys))
        XCTAssertTrue(Set(Self.knownMisses.keys).isSubset(of: Set(Self.answers.keys)))
    }

    func testTheFirstRunsAnswersNowMatchTheirExpectedResults() throws {
        for testCase in try Self.cases() where Self.knownMisses[testCase.id] == nil {
            let (actual, expected) = try Self.replay(testCase)
            XCTAssertEqual(actual, expected, "\(testCase.id) \(testCase.query)")
        }
    }

    /// Once a known miss matches, it no longer needs to be one.
    func testTheKnownMissesStillMiss() throws {
        for testCase in try Self.cases() where Self.knownMisses[testCase.id] != nil {
            let (actual, expected) = try Self.replay(testCase)
            XCTAssertNotEqual(actual, expected, "\(testCase.id): \(Self.knownMisses[testCase.id] ?? "")")
        }
    }

    /// The sentence's answer read and matched as the parser does, and its expected result, both
    /// resolved to ids as the evaluation tool compares them.
    private static func replay(_ testCase: HoldoutFile.Case) throws -> (actual: ItemQuery, expected: ItemQuery) {
        let answer = try XCTUnwrap(answers[testCase.id], testCase.id)
        let output = try XCTUnwrap(ItemQueryModelOutput(text: answer), testCase.id)
        let fields = matcher.fields(for: testCase.query, usage: output.usage, keyword: output.keyword)
        return (vocabulary.resolve(fields), vocabulary.resolve(testCase.expected))
    }

    private static func cases() throws -> [HoldoutFile.Case] {
        let url = try XCTUnwrap(
            Bundle(for: ItemQueryHoldoutRegressionTests.self).url(forResource: "holdout-1", withExtension: "json"),
            "holdout-1.json is not in the test bundle"
        )
        return try JSONDecoder().decode(HoldoutFile.self, from: Data(contentsOf: url)).cases
    }
}
