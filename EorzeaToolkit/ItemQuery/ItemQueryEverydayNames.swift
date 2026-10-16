import Foundation

/// Words players use that the item data has no name for, matched like any other name.
///
/// They were added after the first held-out run, where most misses were sentences such as
/// 「坦用的武器」 (prompts/item-description-search.md, 「比對規則調整」). The matcher keeps only the
/// targets the data and the job filter have, and a longer name still wins over a word inside it.
enum ItemQueryEverydayNames {
    struct Group: Sendable {
        let names: [String]
        let targets: [String]
    }

    /// Job roles, by the item search filter's job abbreviations.
    static let jobGroups: [Group] = [
        Group(names: ["坦", "坦克"], targets: ["PLD", "WAR", "DRK", "GNB"]),
        Group(names: ["補", "補師", "治療"], targets: ["WHM", "SCH", "AST", "SGE"]),
        Group(names: ["近戰"], targets: ["MNK", "DRG", "NIN", "SAM", "RPR", "VPR"]),
        Group(names: ["遠敏", "遠程物理"], targets: ["BRD", "MCH", "DNC"]),
        Group(names: ["法系", "遠程魔法"], targets: ["BLM", "SMN", "RDM", "PCT"]),
        Group(names: ["採集職", "大地使者"], targets: ["MIN", "BTN", "FSH"]),
        Group(names: ["生產職", "能工巧匠"], targets: ["CRP", "BSM", "ARM", "GSM", "LTW", "WVR", "ALC", "CUL"])
    ]
}
