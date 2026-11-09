//
//  SkillRotationEditorStateTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/9.
//

import Testing
import Foundation

@testable import EorzeaToolkit

/// The values the editor derives from its state. The paladin fixture has 先鋒劍 (weaponskill,
/// Lv1), 戰逃反應 (ability, Lv2), 暴亂劍 (weaponskill, Lv4) and 聖靈 (spell, Lv64).
struct SkillRotationEditorStateTests {
    // MARK: - rotation

    @Test func rotationIsTheSelectedLevelsSlots() {
        let level50 = RotationSlot(id: UUID(), action: BattleActionFixture.fastBlade)
        let level100 = RotationSlot(id: UUID(), action: BattleActionFixture.riotBlade)
        let state = BattleActionFixture.editorState(
            rotationsByLevel: [.level50: [level50], .level100: [level100]],
            selectedLevel: .level50
        )

        #expect(state.rotation == [level50])
    }

    @Test func rotationIsEmptyForALevelWithoutSlots() {
        let state = BattleActionFixture.editorState(
            rotationsByLevel: [.level100: [RotationSlot(action: BattleActionFixture.fastBlade)]],
            selectedLevel: .level60
        )

        #expect(state.rotation.isEmpty)
    }

    // MARK: - filteredActions

    @Test func filteredActionsListsEveryLearnedActionForAll() {
        let state = BattleActionFixture.editorState(selectedCategory: .all)

        #expect(state.filteredActions == [
            BattleActionFixture.fastBlade,
            BattleActionFixture.fightOrFlight,
            BattleActionFixture.riotBlade,
            BattleActionFixture.holySpirit,
        ])
    }

    @Test func filteredActionsLeavesOutActionsLearnedAboveTheLevel() {
        // 聖靈 is learned at Lv64.
        let state = BattleActionFixture.editorState(selectedLevel: .level50)

        #expect(state.filteredActions == [
            BattleActionFixture.fastBlade,
            BattleActionFixture.fightOrFlight,
            BattleActionFixture.riotBlade,
        ])
    }

    @Test(arguments: [
        (SkillRotationCategory.weaponskill, [BattleActionFixture.fastBlade.id, BattleActionFixture.riotBlade.id]),
        (.ability, [BattleActionFixture.fightOrFlight.id]),
        (.spell, [BattleActionFixture.holySpirit.id]),
        (.item, []),
    ])
    func filteredActionsKeepsOnlyTheSelectedCategory(category: SkillRotationCategory, expectedIDs: [Int]) {
        let state = BattleActionFixture.editorState(selectedCategory: category)

        #expect(state.filteredActions.map(\.id) == expectedIDs)
    }

    @Test func filteredActionsSortsByLevelThenID() {
        var state = BattleActionFixture.editorState()
        // Out of order on purpose; two actions share Lv1 so the id breaks the tie.
        state.job = BattleActionFixture.job(id: 19, actions: [
            BattleActionFixture.action(id: 40, level: 10),
            BattleActionFixture.action(id: 30, level: 1),
            BattleActionFixture.action(id: 10, level: 1),
        ])

        #expect(state.filteredActions.map(\.id) == [10, 30, 40])
    }

    // MARK: - filteredTinctures

    @Test(arguments: [
        (SkillRotationCategory.all, true),
        (.item, true),
        (.weaponskill, false),
        (.spell, false),
        (.ability, false),
    ])
    func filteredTincturesShowsEveryTinctureOnlyForAllAndItem(category: SkillRotationCategory, showsTinctures: Bool) {
        let state = BattleActionFixture.editorState(selectedCategory: category)

        let expected = showsTinctures ? state.tinctures : []
        #expect(state.filteredTinctures == expected)
    }

    @Test func filteredTincturesDoesNotDependOnTheJob() {
        var state = BattleActionFixture.editorState(selectedCategory: .item)
        // The dexterity tincture is not for the paladin, but the editor lists it anyway, as the
        // view model did.
        state.job = BattleActionFixture.monk

        #expect(state.filteredTinctures == [
            BattleActionFixture.strengthTincture,
            BattleActionFixture.dexterityTincture,
        ])
    }

    // MARK: - showsTinctureSectionSeparator

    @Test func separatorShowsForAllWithActionsAndTinctures() {
        let state = BattleActionFixture.editorState(selectedCategory: .all)

        #expect(state.showsTinctureSectionSeparator)
    }

    @Test(arguments: [SkillRotationCategory.item, .weaponskill, .spell, .ability])
    func separatorIsHiddenForOtherCategories(category: SkillRotationCategory) {
        let state = BattleActionFixture.editorState(selectedCategory: category)

        #expect(!state.showsTinctureSectionSeparator)
    }

    @Test func separatorIsHiddenWithoutActions() {
        var state = BattleActionFixture.editorState(selectedCategory: .all)
        state.job = BattleActionFixture.job(id: 19, actions: [])

        #expect(!state.showsTinctureSectionSeparator)
    }

    @Test func separatorIsHiddenWithoutTinctures() {
        var state = BattleActionFixture.editorState(selectedCategory: .all)
        state.tinctures = []

        #expect(!state.showsTinctureSectionSeparator)
    }

    // MARK: - statName

    @Test func statNameUsesTheCatalogName() {
        let state = BattleActionFixture.editorState()

        #expect(state.statName(for: BattleActionFixture.strengthTincture) == "力量")
        #expect(state.statName(for: BattleActionFixture.dexterityTincture) == "靈巧")
    }

    @Test func statNameFallsBackToTheStatKey() {
        let state = BattleActionFixture.editorState()
        let tincture = BattleActionFixture.tincture(id: 1, name: "智力之寶藥", stat: "intelligence")

        #expect(state.statName(for: tincture) == "intelligence")
    }
}
