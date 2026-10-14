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

        for key in ItemQueryFields.CodingKeys.allCases {
            XCTAssertTrue(text.contains(key.rawValue), "\(key.rawValue) is not explained")
        }
    }
}
