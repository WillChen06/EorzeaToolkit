import Foundation

/// Why a parsed sentence was not applied, as the 「描述搜尋畫面」 table of
/// prompts/item-description-search.md lists it. The screen stays open and shows it.
enum ItemDescriptionSearchMessage: Equatable, Sendable {
    /// Usage 「無法處理」, or a recipe lookup without a keyword.
    case notAnItemQuery
    /// A search with neither a keyword nor any condition.
    case nothingFound
    /// The guardrails declined, the answer could not be read, or anything else went wrong.
    case failed
}

/// The sentence last searched with, for as long as the app runs. The item search screen is
/// rebuilt each time it opens, so the sentence is kept here rather than in its view model.
@MainActor
final class ItemDescriptionSearchMemory {
    static let shared = ItemDescriptionSearchMemory()

    var lastSubmittedSentence = ""
}

/// The sentence field wraps long sentences but never breaks them.
enum ItemDescriptionInput {
    /// The field's text after an edit, and whether the edit was the return key, which searches.
    /// A single newline added to the old text is the return key; newlines arriving any other
    /// way, such as in pasted text, become spaces.
    static func edit(from oldText: String, to newText: String) -> (text: String, submits: Bool) {
        guard newText.contains(where: \.isNewline) else {
            return (newText, false)
        }

        let newlineCount = newText.filter(\.isNewline).count
        let withoutNewlines = newText.filter { !$0.isNewline }
        if newlineCount == 1, withoutNewlines == oldText {
            return (oldText, true)
        }

        let lines = newText.split(whereSeparator: \.isNewline)
        return (lines.joined(separator: " "), false)
    }
}

extension ItemQuery {
    /// Whether the sentence named any condition besides a keyword.
    var hasConditions: Bool {
        !categoryIds.isEmpty || !equipSlotIds.isEmpty || !jobs.isEmpty
            || equipLevelRange != nil || itemLevelRange != nil || !rarities.isEmpty
            || hq != nil || tradable != nil
    }
}

extension ItemFilter {
    /// The filter a parsed sentence asks for. Whatever the sentence did not mention stays at
    /// its default (prompts/item-description-search.md, 「套用」).
    init(query: ItemQuery) {
        self.init()
        selectedUICategoryIds = query.categoryIds
        // Already every variant of each body part, such as 「身體（無法裝備頭部）」.
        selectedEquipSlots = query.equipSlotIds
        selectedJobAbbrs = query.jobs
        equipLevelRange = query.equipLevelRange ?? Self.defaultEquipLevelRange
        ilvlRange = query.itemLevelRange ?? Self.defaultIlvlRange
        selectedRarities = query.rarities.isEmpty ? Self.defaultRarities : query.rarities
        hqState = ItemBoolFilterState(query.hq)
        tradableState = ItemBoolFilterState(query.tradable)
    }
}

extension ItemBoolFilterState {
    /// Yes keeps only the matching items, no leaves them out, and nil keeps everything.
    init(_ value: Bool?) {
        switch value {
        case true?:
            self = .only
        case false?:
            self = .exclude
        case nil:
            self = .any
        }
    }
}
