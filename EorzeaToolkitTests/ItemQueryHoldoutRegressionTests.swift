import XCTest
@testable import EorzeaToolkit

/// The held-out runs replayed through the matching rules: each run's model answers, read and
/// matched again, against the expected results the user confirmed in holdout-1.json and
/// holdout-2.json. The rules were adjusted to these sentences, so they guard against going back
/// (AC-34, AC-42).
final class ItemQueryHoldoutRegressionTests: XCTestCase {
    private struct HoldoutFile: Decodable {
        struct Case: Decodable {
            let id: String
            let query: String
            let expected: ItemQueryFields
        }

        let cases: [Case]
    }

    private struct Run {
        /// The set's file name in the test bundle.
        let file: String
        let sentenceCount: Int
        /// The model's answer to each sentence, as docs/foundation-models-eval.md records it, with
        /// each 「 / 」 back on its own line.
        ///
        /// The report prints answers only for the sentences it got wrong. The others are rebuilt
        /// from their expected results. That loses nothing for a recipe lookup, which keeps only
        /// its keyword as the model gave it, or a sentence that cannot be handled, which keeps only
        /// its usage; for a search the model's keyword may have differed and been dropped, so
        /// running the set on the Mac is the check with the real answers.
        let answers: [String: String]
        /// Sentences the rules do not cover in this phase (prompts/item-description-search.md).
        let knownMisses: [String: String]
    }

    private static let firstRun = Run(
        file: "holdout-1",
        sentenceCount: 24,
        answers: [
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
        ],
        knownMisses: [
            "holdout-02": "爆發藥 is players' name for 寶藥; such nicknames are left for later",
            "holdout-g04": "副工具 is a category, which selects the same items as the 副手 body part"
        ]
    )

    private static let secondRun = Run(
        file: "holdout-2",
        sentenceCount: 28,
        answers: [
            "holdout-g01": "用法：搜尋", // rebuilt
            "holdout-g02": "用法：搜尋", // rebuilt
            "holdout-g03": "用法：查配方\n關鍵字：鐵錠", // rebuilt
            "holdout-g04": "用法：搜尋", // rebuilt
            "holdout-g05": "用法：搜尋", // rebuilt
            "holdout-g06": "用法：搜尋\n關鍵字：毒蛇",
            "holdout-g07": "用法：搜尋\n關鍵字：亞拉戈", // rebuilt
            "holdout-g08": "用法：搜尋\n關鍵字：料理",
            "holdout-g09": "用法：搜尋\n關鍵字：drg槍",
            "holdout-g10": "用法：搜尋", // rebuilt
            "holdout-g11": "用法：搜尋\n關鍵字：il600",
            "holdout-g12": "用法：搜尋\n關鍵字：武士刀",
            "holdout-g13": "用法：查配方\n關鍵字：強心劑", // rebuilt
            "holdout-g14": "用法：搜尋\n關鍵字：暗物",
            "holdout-g15": "用法：搜尋", // rebuilt
            "holdout-g16": "用法：搜尋", // rebuilt
            "holdout-g17": "用法：搜尋\n關鍵字：魔晶石",
            "holdout-g18": "用法：搜尋\n關鍵字：絕槍",
            "holdout-g19": "用法：搜尋\n關鍵字：耳環",
            "holdout-g20": "用法：搜尋\n關鍵字：陸行鳥", // rebuilt
            "holdout-g21": "用法：搜尋", // rebuilt
            "holdout-g22": "用法：搜尋\n關鍵字：雙手杖",
            "holdout-g23": "用法：查配方\n關鍵字：麻布", // rebuilt
            "holdout-g24": "用法：搜尋", // rebuilt
            "holdout-g25": "用法：搜尋\n關鍵字：七十到八十",
            "holdout-g26": "用法：搜尋\n關鍵字：紫武",
            "holdout-g27": "用法：搜尋\n關鍵字：血紅色染劑",
            "holdout-g28": "用法：搜尋\n關鍵字：鞋子"
        ],
        knownMisses: [
            "holdout-g06": "the expected result has the main hand only; 武器 is either hand",
            "holdout-g08": "the model judged a sentence about an effect a search",
            "holdout-g14": "暗物 is players' name for 暗物質; such nicknames are left for later",
            "holdout-g18": "the model judged a sentence that is no item search a search",
            "holdout-g26": "the expected result has the main hand only; 紫武 is either hand",
            "holdout-g27": "the model's keyword is not the sentence's text, so it is dropped",
            "holdout-g28": "the model judged a sentence that is no item search a search"
        ]
    )

    private static let vocabulary: ItemQueryVocabulary = {
        let data: ItemDataResponse = try! LocalDataService.load("items")
        return ItemQueryVocabulary(data: data)
    }()

    private static let matcher = ItemQueryMatcher(vocabulary: vocabulary)

    func testEverySentenceHasItsAnswer() throws {
        for run in [Self.firstRun, Self.secondRun] {
            let cases = try Self.cases(of: run)

            XCTAssertEqual(cases.count, run.sentenceCount, run.file)
            XCTAssertEqual(Set(cases.map(\.id)), Set(run.answers.keys), run.file)
            XCTAssertTrue(Set(run.knownMisses.keys).isSubset(of: Set(run.answers.keys)), run.file)
        }
    }

    func testTheFirstRunsAnswersNowMatchTheirExpectedResults() throws {
        try assertAnswersMatch(Self.firstRun)
    }

    func testTheSecondRunsAnswersNowMatchTheirExpectedResults() throws {
        try assertAnswersMatch(Self.secondRun)
    }

    /// Once a known miss matches, it no longer needs to be one.
    func testTheKnownMissesStillMiss() throws {
        for run in [Self.firstRun, Self.secondRun] {
            for testCase in try Self.cases(of: run) where run.knownMisses[testCase.id] != nil {
                let (actual, expected) = try Self.replay(testCase, in: run)
                XCTAssertNotEqual(actual, expected, "\(run.file) \(testCase.id): \(run.knownMisses[testCase.id] ?? "")")
            }
        }
    }

    private func assertAnswersMatch(_ run: Run, file: StaticString = #filePath, line: UInt = #line) throws {
        for testCase in try Self.cases(of: run) where run.knownMisses[testCase.id] == nil {
            let (actual, expected) = try Self.replay(testCase, in: run)
            XCTAssertEqual(actual, expected, "\(testCase.id) \(testCase.query)", file: file, line: line)
        }
    }

    /// The sentence's answer read and matched as the parser does, and its expected result, both
    /// resolved to ids as the evaluation tool compares them.
    private static func replay(_ testCase: HoldoutFile.Case, in run: Run) throws -> (actual: ItemQuery, expected: ItemQuery) {
        let answer = try XCTUnwrap(run.answers[testCase.id], testCase.id)
        let output = try XCTUnwrap(ItemQueryModelOutput(text: answer), testCase.id)
        let fields = matcher.fields(for: testCase.query, usage: output.usage, keyword: output.keyword)
        return (vocabulary.resolve(fields), vocabulary.resolve(testCase.expected))
    }

    private static func cases(of run: Run) throws -> [HoldoutFile.Case] {
        let url = try XCTUnwrap(
            Bundle(for: ItemQueryHoldoutRegressionTests.self).url(forResource: run.file, withExtension: "json"),
            "\(run.file).json is not in the test bundle"
        )
        return try JSONDecoder().decode(HoldoutFile.self, from: Data(contentsOf: url)).cases
    }
}
