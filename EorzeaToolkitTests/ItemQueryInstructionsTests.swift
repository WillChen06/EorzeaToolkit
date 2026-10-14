import XCTest
@testable import EorzeaToolkit

/// The model only answers the usage and the keyword, so the instructions must explain both and
/// their examples must be answers the parser keeps as they stand.
final class ItemQueryInstructionsTests: XCTestCase {
    func testInstructionsNameEveryFieldAndUsage() {
        let text = ItemQueryInstructions.text

        for label in [ItemQueryModelOutput.usageLabel, ItemQueryModelOutput.keywordLabel] {
            XCTAssertTrue(text.contains(label), "\(label) is not explained")
        }
        for usage in ItemQuery.Usage.allCases {
            XCTAssertTrue(text.contains(usage.label), "\(usage.label) is not explained")
        }
    }

    func testExamplesShowEveryUsage() {
        let usages = ItemQueryInstructions.examples.compactMap(\.answer.usage)

        XCTAssertEqual(Set(usages), Set(ItemQuery.Usage.allCases.map(\.label)))
    }

    /// An example the parser would read differently, or whose keyword the matcher would drop,
    /// teaches the wrong answer.
    func testExamplesAreAnswersTheParserKeepsWhole() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")
        let matcher = ItemQueryMatcher(vocabulary: ItemQueryVocabulary(data: data))
        let text = ItemQueryInstructions.text

        for example in ItemQueryInstructions.examples {
            XCTAssertTrue(text.contains(example.answer.text), example.sentence)
            XCTAssertEqual(ItemQueryModelOutput(text: example.answer.text), example.answer, example.sentence)

            let fields = matcher.fields(for: example.sentence, usage: example.answer.usage, keyword: example.answer.keyword)
            XCTAssertEqual(fields.keyword, example.answer.keyword, example.sentence)
        }
    }
}
