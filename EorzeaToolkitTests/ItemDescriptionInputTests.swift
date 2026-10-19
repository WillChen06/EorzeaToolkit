import XCTest
@testable import EorzeaToolkit

/// The sentence field wraps but never breaks lines: the return key searches (AC-22).
final class ItemDescriptionInputTests: XCTestCase {
    func testTypingKeepsTheText() {
        let edit = ItemDescriptionInput.edit(from: "白魔", to: "白魔的")

        XCTAssertEqual(edit.text, "白魔的")
        XCTAssertFalse(edit.submits)
    }

    func testTheReturnKeySearchesWithoutABreak() {
        for newText in ["白魔的頭\n", "白魔的\n頭", "\n白魔的頭"] {
            let edit = ItemDescriptionInput.edit(from: "白魔的頭", to: newText)

            XCTAssertEqual(edit.text, "白魔的頭", newText)
            XCTAssertTrue(edit.submits, newText)
        }
    }

    /// Pasted lines join with spaces, and pasting does not search.
    func testPastedLinesJoinWithoutSearching() {
        let edit = ItemDescriptionInput.edit(from: "", to: "白魔的頭\n80級以上\r\n")

        XCTAssertEqual(edit.text, "白魔的頭 80級以上")
        XCTAssertFalse(edit.submits)
    }

    /// Only one line break at a time is the return key; pasted blank lines are not.
    func testPastedBlankLinesAreNotTheReturnKey() {
        let edit = ItemDescriptionInput.edit(from: "白魔", to: "白魔\n\n")

        XCTAssertEqual(edit.text, "白魔")
        XCTAssertFalse(edit.submits)
    }

    func testAPastedLineBreakIsNotTheReturnKey() {
        let edit = ItemDescriptionInput.edit(from: "白魔", to: "白魔\n的頭")

        XCTAssertEqual(edit.text, "白魔 的頭")
        XCTAssertFalse(edit.submits)
    }
}
