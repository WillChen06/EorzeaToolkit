//
//  BattleActionFixture.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/8.
//

@testable import EorzeaToolkit

/// A small battle action catalog for tests. Ids and names follow the bundled data, but the
/// fixture does not read it, so tests do not change when the data is regenerated.
enum BattleActionFixture {
    // MARK: - Paladin

    static let fastBlade = action(id: 9, name: "先鋒劍", category: "weaponskill", level: 1)
    static let fightOrFlight = action(id: 20, name: "戰逃反應", category: "ability", level: 2)
    static let riotBlade = action(id: 15, name: "暴亂劍", category: "weaponskill", level: 4)
    static let holySpirit = action(id: 7384, name: "聖靈", category: "spell", level: 64)

    static let paladin = job(
        id: 19,
        name: "騎士",
        abbreviation: "PLD",
        actions: [fastBlade, fightOrFlight, riotBlade, holySpirit]
    )

    // MARK: - Monk

    static let bootshine = action(id: 53, name: "連擊", category: "weaponskill", level: 1)

    static let monk = job(id: 20, name: "武僧", abbreviation: "MNK", actions: [bootshine])

    // MARK: - Tinctures

    static let strengthTincture = tincture(id: 44157, name: "剛力之寶藥", stat: "strength")
    static let dexterityTincture = tincture(id: 44158, name: "巧力之寶藥", stat: "dexterity")

    // MARK: - Catalog

    static func catalog(
        jobs: [BattleJob] = [paladin, monk],
        tinctures: [Tincture] = [strengthTincture, dexterityTincture],
        tinctureStatJobs: [String: TinctureStatJob] = [
            "strength": TinctureStatJob(nameTw: "力量", jobs: ["PLD", "MNK"]),
            "dexterity": TinctureStatJob(nameTw: "靈巧", jobs: ["BRD"]),
        ]
    ) -> BattleActionsData {
        BattleActionsData(jobs: jobs, tinctures: tinctures, tinctureStatJobs: tinctureStatJobs)
    }

    // MARK: - Factories

    static func job(
        id: Int,
        name: String = "騎士",
        abbreviation: String = "PLD",
        actions: [BattleAction] = []
    ) -> BattleJob {
        BattleJob(
            id: id,
            nameTw: name,
            abbreviation: abbreviation,
            iconId: 0,
            iconPath: "",
            actions: actions
        )
    }

    static func action(
        id: Int,
        name: String = "先鋒劍",
        category: String = "weaponskill",
        level: Int = 1,
        descriptions: [Int: String] = [:]
    ) -> BattleAction {
        BattleAction(
            id: id,
            nameTw: name,
            iconId: 0,
            iconPath: "",
            category: category,
            level: level,
            range: -1,
            effectRange: 0,
            cast100ms: 0,
            recast100ms: 25,
            maxCharges: 0,
            descriptions: descriptions
        )
    }

    static func tincture(
        id: Int,
        name: String = "剛力之寶藥",
        itemLevel: Int = 690,
        stat: String = "strength"
    ) -> Tincture {
        Tincture(
            id: id,
            nameTw: name,
            iconId: 0,
            iconPath: "",
            itemLevel: itemLevel,
            stat: stat
        )
    }
}
