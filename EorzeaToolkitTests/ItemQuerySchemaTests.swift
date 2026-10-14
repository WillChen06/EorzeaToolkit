import XCTest
@testable import EorzeaToolkit

/// The schema is built from the item data at runtime, so a name the schema cannot hold would
/// only show up when the model is first asked. Building it needs no model, only iOS 26.
final class ItemQuerySchemaTests: XCTestCase {
    func testSchemaBuildsFromTheBundledVocabulary() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("FoundationModels needs iOS 26 or later.")
        }

        let data: ItemDataResponse = try LocalDataService.load("items")

        XCTAssertNoThrow(try ItemQuerySchema.make(for: ItemQueryVocabulary(data: data)))
    }
}
