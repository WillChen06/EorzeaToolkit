import Foundation

/// The instructions the model gets before each sentence.
///
/// The model only judges the usage and picks out the keyword; `ItemQueryMatcher` finds every
/// other condition in the sentence. Both are explained with complete sentence → answer examples
/// rather than single values: in the first evaluation run the model copied such values into
/// sentences that never mentioned them. None of the examples comes from the evaluation set.
///
/// The text is fixed, so the model's answers can be compared between runs.
enum ItemQueryInstructions {
    /// Sentences and the answers the model should give.
    static let examples: [(sentence: String, answer: ItemQueryModelOutput)] = [
        ("戰士95級以上能穿的手部裝備", ItemQueryModelOutput(usage: ItemQuery.Usage.search.label)),
        ("白魔能穿的歐米茄身體裝備", ItemQueryModelOutput(usage: ItemQuery.Usage.search.label, keyword: "歐米茄")),
        ("高級強心劑怎麼做", ItemQueryModelOutput(usage: ItemQuery.Usage.recipe.label, keyword: "高級強心劑")),
        ("今天天氣如何", ItemQueryModelOutput(usage: ItemQuery.Usage.unsupported.label))
    ]

    static let text: String = {
        let usage = ItemQueryModelOutput.usageLabel
        let keyword = ItemQueryModelOutput.keywordLabel
        let exampleText = examples
            .map { "句子：\($0.sentence)\n回答：\n\($0.answer.text)" }
            .joined(separator: "\n\n")

        return """
        你把玩家輸入的一句話，轉成《FINAL FANTASY XIV》繁體中文版的道具搜尋。只回答「\(usage)：」和「\(keyword)：」開頭的兩行，不加其他文字。職業、部位、分類、等級、稀有度、HQ、能不能交易這些條件由程式從句子裡找，不要放進\(keyword)。不回答問題，也不推薦道具。

        \(usage)：
        - 用條件或名稱找道具：\(ItemQuery.Usage.search.label)
        - 問某個道具要什麼材料、怎麼製作：\(ItemQuery.Usage.recipe.label)
        - 描述用途或效果，或跟道具無關：\(ItemQuery.Usage.unsupported.label)

        \(keyword)：句子裡的道具名稱，或玩家說名稱裡有的字。從句子原封不動照抄，不補全、不改寫。句子只有條件、沒提到道具名稱時，省略\(keyword)這一行；\(usage)是\(ItemQuery.Usage.unsupported.label)時也省略。

        範例：

        \(exampleText)
        """
    }()
}
