import XCTest
@testable import EorzeaToolkit

/// The model only answers the usage and the keyword, so the instructions must explain both and
/// their examples must be answers the parser keeps as they stand.
final class ItemQueryInstructionsTests: XCTestCase {
    func testInstructionsNameEveryFieldAndUsage() {
        let text = ItemQueryInstructions.text

        for key in ItemQueryModelOutput.CodingKeys.allCases {
            XCTAssertTrue(text.contains(key.rawValue), "\(key.rawValue) is not explained")
        }
        for usage in ItemQuery.Usage.allCases {
            XCTAssertTrue(text.contains(usage.label), "\(usage.label) is not explained")
        }
    }

    func testExamplesShowEveryUsage() throws {
        let usages = try ItemQueryInstructions.examples.map { example -> String? in
            try JSONDecoder().decode(ItemQueryModelOutput.self, from: Data(example.answer.utf8)).usage
        }

        XCTAssertEqual(Set(usages.compactMap { $0 }), Set(ItemQuery.Usage.allCases.map(\.label)))
    }

    /// Each example may hold only the schema's keys, and its keyword must survive the checks
    /// against its sentence; an example the parser would change teaches the wrong answer.
    func testExamplesAreAnswersTheParserKeepsWhole() throws {
        let data: ItemDataResponse = try LocalDataService.load("items")
        let matcher = ItemQueryMatcher(vocabulary: ItemQueryVocabulary(data: data))
        let keys = Set(ItemQueryModelOutput.CodingKeys.allCases.map(\.rawValue))

        for example in ItemQueryInstructions.examples {
            let json = Data(example.answer.utf8)
            let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: json) as? [String: Any])
            XCTAssertTrue(Set(object.keys).isSubset(of: keys), example.sentence)

            let answer = try JSONDecoder().decode(ItemQueryModelOutput.self, from: json)
            let fields = matcher.fields(for: example.sentence, usage: answer.usage, keyword: answer.keyword)
            XCTAssertNotNil(answer.usage.flatMap { ItemQuery.Usage(label: $0) }, example.sentence)
            XCTAssertEqual(fields.keyword, answer.keyword, example.sentence)
        }
    }
}
