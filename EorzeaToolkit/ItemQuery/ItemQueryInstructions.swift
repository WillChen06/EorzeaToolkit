import Foundation

/// The instructions the model gets before each sentence.
///
/// The categories and body parts reach the model through the schema's choices, so they are not
/// repeated here. Jobs are listed with their other names, since a player rarely types the
/// official one. The fields are explained with complete sentence → answer examples rather than
/// single values: in the first evaluation run the model copied such values (「80級」, 藥品) into
/// sentences that never mentioned them. None of the examples comes from the evaluation set.
///
/// Everything is built in a fixed order, so the same data always yields the same text and the
/// model's answers can be compared between runs.
enum ItemQueryInstructions {
    /// Sentences and the answers the model should give, in the schema's keys.
    static let examples: [(sentence: String, answer: String)] = [
        (
            "戰士95級以上能穿的手部裝備",
            #"{"usage":"搜尋","slots":[{"quote":"手部","name":"手部"}],"jobs":[{"quote":"戰士","name":"戰士"}],"equipLevel":{"quote":"95級以上","min":95}}"#
        ),
        (
            "高級強心劑怎麼做",
            #"{"usage":"查配方","keyword":"高級強心劑"}"#
        ),
        (
            "今天天氣如何",
            #"{"usage":"無法處理"}"#
        )
    ]

    static func text(for vocabulary: ItemQueryVocabulary) -> String {
        typealias Key = ItemQueryModelOutput.CodingKeys
        typealias Nested = ItemQueryModelOutput.NestedKey

        let jobLines = vocabulary.jobs
            .map { job in "- \(job.choice)：\((job.nicknames + [job.abbreviation]).joined(separator: "、"))" }
            .joined(separator: "\n")
        let rarities = ItemQueryVocabulary.rarities
            .map { "\($0.name)（\($0.colour)）" }
            .joined(separator: "、")
        let hq = ItemQueryVocabulary.hqLabels
        let tradable = ItemQueryVocabulary.tradableLabels
        let examples = Self.examples
            .map { "句子：\($0.sentence)\n結果：\($0.answer)" }
            .joined(separator: "\n\n")

        return """
        你把玩家輸入的一句話，轉成《FINAL FANTASY XIV》繁體中文版的道具搜尋條件。只填句子裡明確提到的條件，沒提到的欄位一律不填。不回答問題，也不推薦道具。

        每個條件都要在 \(Nested.quote.rawValue) 填上它在句子裡的依據：從句子原封不動照抄的一段連續的字。句子裡找不到依據的條件就不要填。

        \(Key.usage.rawValue)：
        - 用條件或名稱找道具：\(ItemQuery.Usage.search.label)
        - 問某個道具要什麼材料、怎麼製作：\(ItemQuery.Usage.recipe.label)
        - 描述用途或效果，或跟道具無關：\(ItemQuery.Usage.unsupported.label)，其他欄位都不填

        \(Key.keyword.rawValue)：句子裡出現的道具名稱，照抄，不補全、不改寫。分類、部位、職業的名稱不是 \(Key.keyword.rawValue)。
        \(Key.categories.rawValue)：武器或工具的種類、盾，或不能裝備的道具的種類。
        \(Key.slots.rawValue)：防具和飾品裝在哪個部位。
        \(Key.jobs.rawValue)：能使用的職業。冒號後面是玩家常用的其他叫法：
        \(jobLines)

        \(Key.equipLevel.rawValue)：裝備等級。只說「X級」時 \(Nested.min.rawValue) 和 \(Nested.max.rawValue) 都填 X；「X級以上」只填 \(Nested.min.rawValue)；「X級以下」只填 \(Nested.max.rawValue)。
        \(Key.itemLevel.rawValue)：品級。只有句子說了「品級」「iLv」「裝等」才填，填法和 \(Key.equipLevel.rawValue) 相同。沒說品級的「X級」都是 \(Key.equipLevel.rawValue)。
        \(Key.rarities.rawValue)：\(rarities)。
        \(Key.hq.rawValue)：\(hq.yes)、\(hq.no)。
        \(Key.tradable.rawValue)：\(tradable.yes)、\(tradable.no)。能在市場板買賣就是\(tradable.yes)。

        範例：

        \(examples)
        """
    }
}
