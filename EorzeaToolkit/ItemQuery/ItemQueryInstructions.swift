import Foundation

/// The instructions the model gets before each sentence.
///
/// The categories and body parts reach the model through the schema's choices, so they are not
/// repeated here. Jobs are listed with their other names, since a player rarely types the
/// official one. Everything is built in a fixed order, so the same data always yields the same
/// text and the model's answers can be compared between runs.
enum ItemQueryInstructions {
    static func text(for vocabulary: ItemQueryVocabulary) -> String {
        typealias Key = ItemQueryFields.CodingKeys

        let jobLines = vocabulary.jobs
            .map { job in "- \(job.choice)：\((job.nicknames + [job.abbreviation]).joined(separator: "、"))" }
            .joined(separator: "\n")
        let rarities = ItemQueryVocabulary.rarities
            .map { "\($0.name)（\($0.colour)）" }
            .joined(separator: "、")
        let hq = ItemQueryVocabulary.hqLabels
        let tradable = ItemQueryVocabulary.tradableLabels

        return """
        你把玩家輸入的一句話，轉成《FINAL FANTASY XIV》繁體中文版的道具搜尋條件。只填條件，不回答問題，也不推薦道具。句子沒提到的欄位不要填。

        \(Key.usage.rawValue)：
        - 用條件或名稱找道具：\(ItemQuery.Usage.search.label)
        - 問某個道具要什麼材料、怎麼製作：\(ItemQuery.Usage.recipe.label)
        - 描述用途或效果，或跟道具無關：\(ItemQuery.Usage.unsupported.label)，其他欄位都不填

        \(Key.keyword.rawValue)：道具名稱的一部分，只能照抄句子裡連續的字，不補全、不翻譯、不改寫。查配方時填那個道具的名稱。

        \(Key.categories.rawValue)：武器或工具的種類、盾、靈魂水晶，以及藥品、食材這類不能裝備的道具。防具和飾品不用分類。
        \(Key.slots.rawValue)：防具和飾品的部位。盾不用部位。

        \(Key.jobs.rawValue)：能使用的職業。冒號後面是玩家常用的其他叫法：
        \(jobLines)

        \(Key.equipLevelMin.rawValue)、\(Key.equipLevelMax.rawValue)：裝備等級。「80級」兩個都填 80；「80級以上」只填 \(Key.equipLevelMin.rawValue)；「80級以下」只填 \(Key.equipLevelMax.rawValue)。沒說是品級的「X級」都是裝備等級。
        \(Key.itemLevelMin.rawValue)、\(Key.itemLevelMax.rawValue)：品級。只有句子說了「品級」「iLv」「裝等」才填，規則和裝備等級相同。

        \(Key.rarities.rawValue)：\(rarities)。
        \(Key.hq.rawValue)：\(hq.yes)、\(hq.no)。
        \(Key.tradable.rawValue)：\(tradable.yes)、\(tradable.no)。可以在市場板買賣的就是\(tradable.yes)。
        """
    }
}
