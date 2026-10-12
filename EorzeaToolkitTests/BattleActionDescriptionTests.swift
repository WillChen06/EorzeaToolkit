import XCTest
@testable import EorzeaToolkit

/// A skill's description depends on the player's level: potencies and follow-up effects change
/// as traits are learned. The rotation editor lets the player pick a level, so the description
/// shown must be the one for that level, not the level cap's.
final class BattleActionDescriptionTests: XCTestCase {
    private func action(from json: String) throws -> BattleAction {
        try JSONDecoder().decode(BattleAction.self, from: Data(json.utf8))
    }

    private let fields = #""id":15,"name_tw":"暴亂劍","icon_id":0,"icon_path":"","category":"weaponskill","level":4,"range":-1,"effect_range":0,"cast_100ms":0,"recast_100ms":25,"max_charges":0"#

    func testReturnsTheDescriptionForTheSelectedLevel() throws {
        let action = try action(from: #"{\#(fields),"descriptions":{"70":"威力：100","100":"威力：170"}}"#)

        XCTAssertEqual(action.description(at: 70), "威力：100")
        XCTAssertEqual(action.description(at: 100), "威力：170")
    }

    /// A level the data has no description for is one the action is not learned at; another
    /// level's text must not stand in for it.
    func testReturnsNothingForALevelWithoutADescription() throws {
        let action = try action(from: #"{\#(fields),"descriptions":{"70":"威力：100","100":"威力：170"}}"#)

        XCTAssertNil(action.description(at: 60))
    }
}
