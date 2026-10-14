import XCTest
@testable import EorzeaToolkit

/// The model's answers are only comparable between runs if the instructions are identical, and
/// only useful if every job is introduced with the names players type.
final class ItemQueryInstructionsTests: XCTestCase {
    private func bundledVocabulary() throws -> ItemQueryVocabulary {
        let data: ItemDataResponse = try LocalDataService.load("items")
        return ItemQueryVocabulary(data: data)
    }

    func testTheSameDataYieldsTheSameInstructions() throws {
        let first = ItemQueryInstructions.text(for: try bundledVocabulary())
        let second = ItemQueryInstructions.text(for: try bundledVocabulary())

        XCTAssertEqual(first, second)
    }

    func testEveryJobIsListedWithItsOtherNamesInFilterOrder() throws {
        let vocabulary = try bundledVocabulary()
        let text = ItemQueryInstructions.text(for: vocabulary)

        XCTAssertTrue(text.contains("- 白魔道士：白魔、WHM\n"), text)

        let positions = vocabulary.jobs.map { job -> String.Index? in
            text.range(of: "- \(job.choice)：")?.lowerBound
        }
        XCTAssertFalse(positions.contains(nil), "a job is missing from the instructions")
        XCTAssertEqual(positions.compactMap { $0 }, positions.compactMap { $0 }.sorted())
    }

    func testInstructionsNameEveryField() throws {
        let text = ItemQueryInstructions.text(for: try bundledVocabulary())

        for key in ItemQueryModelOutput.CodingKeys.allCases {
            XCTAssertTrue(text.contains(key.rawValue), "\(key.rawValue) is not explained")
        }
    }

    /// The examples teach the answer's shape, so each must be an answer the parser accepts as
    /// it stands: only schema keys, names from the lists, and quotes taken from its sentence.
    func testExamplesAreAnswersTheParserKeepsWhole() throws {
        let vocabulary = try bundledVocabulary()
        let topKeys = Set(ItemQueryModelOutput.CodingKeys.allCases.map(\.rawValue))

        for example in ItemQueryInstructions.examples {
            let data = Data(example.answer.utf8)
            let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            XCTAssertTrue(Set(object.keys).isSubset(of: topKeys), example.sentence)

            let answer = try JSONDecoder().decode(ItemQueryModelOutput.self, from: data)
            let fields = ItemQueryEvidence.fields(from: answer, sentence: example.sentence)
            let names = (answer.slots ?? []).compactMap(\.name)
            let jobs = (answer.jobs ?? []).compactMap(\.name)

            XCTAssertEqual(fields.slots ?? [], names, "a slot quote is not in 「\(example.sentence)」")
            XCTAssertEqual(fields.jobs ?? [], jobs, "a job quote is not in 「\(example.sentence)」")
            XCTAssertEqual(fields.equipLevelMin, answer.equipLevel?.min, example.sentence)
            XCTAssertEqual(fields.keyword, answer.keyword, example.sentence)
            XCTAssertEqual(vocabulary.equipSlotIds(named: names).isEmpty, names.isEmpty, example.sentence)
            XCTAssertEqual(vocabulary.jobAbbreviations(named: jobs).count, jobs.count, example.sentence)
        }
    }
}
