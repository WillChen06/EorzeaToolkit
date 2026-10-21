import XCTest
@testable import EorzeaToolkit

final class EquipSlotFilterSectionsTests: XCTestCase {
    func testSplitsARestrictedNameIntoItsSlotAndRestriction() {
        let slot = EquipSlot(id: 16, nameTw: "身體（無法裝備手部、腿部、腳部）")

        XCTAssertEqual(slot.baseName, "身體")
        XCTAssertEqual(slot.restriction, "無法裝備手部、腿部、腳部")
        XCTAssertEqual(slot.displayName, "身體（無法裝備手部、腿部、腳部）")
    }

    func testLeavesAPlainNameWhole() {
        let slot = EquipSlot(id: 17, nameTw: "靈魂水晶")

        XCTAssertEqual(slot.baseName, "靈魂水晶")
        XCTAssertNil(slot.restriction)
    }

    func testGroupsRestrictedVariantsInTheOrderOfTheirSlots() {
        let slots = [
            EquipSlot(id: 1, nameTw: "主手"),
            EquipSlot(id: 4, nameTw: "身體"),
            EquipSlot(id: 7, nameTw: "腿部"),
            EquipSlot(id: 13, nameTw: "主手（無法裝備副手）"),
            EquipSlot(id: 15, nameTw: "身體（無法裝備頭部）"),
            EquipSlot(id: 18, nameTw: "腿部（無法裝備腳部）"),
            EquipSlot(id: 19, nameTw: "身體（無法裝備頭部、手部、腿部、腳部）")
        ]

        let sections = EquipSlot.filterSections(slots)

        XCTAssertEqual(sections.base.map(\.id), [1, 4, 7])
        XCTAssertEqual(sections.restricted.map(\.id), [13, 15, 19, 18])
    }
}
