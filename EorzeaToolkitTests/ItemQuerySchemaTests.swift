import XCTest
@testable import EorzeaToolkit

/// The schema is built at runtime, so a schema the framework rejects would only show up when the
/// model is first asked. Building it needs no model, only iOS 26.
final class ItemQuerySchemaTests: XCTestCase {
    func testSchemaBuilds() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("FoundationModels needs iOS 26 or later.")
        }

        XCTAssertNoThrow(try ItemQuerySchema.make())
    }
}
