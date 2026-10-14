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
    /// Sentences and the answers the model should give, in the schema's keys.
    static let examples: [(sentence: String, answer: String)] = [
        (
            "戰士95級以上能穿的手部裝備",
            #"{"usage":"搜尋"}"#
        ),
        (
            "白魔能穿的歐米茄身體裝備",
            #"{"usage":"搜尋","keyword":"歐米茄"}"#
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

    static let text: String = {
        typealias Key = ItemQueryModelOutput.CodingKeys

        let exampleText = examples
            .map { "句子：\($0.sentence)\n結果：\($0.answer)" }
            .joined(separator: "\n\n")

        return """
        你把玩家輸入的一句話，轉成《FINAL FANTASY XIV》繁體中文版的道具搜尋。你只填 \(Key.usage.rawValue) 和 \(Key.keyword.rawValue)。職業、部位、分類、等級、稀有度、HQ、能不能交易這些條件由程式從句子裡找，不要放進 \(Key.keyword.rawValue)。不回答問題，也不推薦道具。

        \(Key.usage.rawValue)：
        - 用條件或名稱找道具：\(ItemQuery.Usage.search.label)
        - 問某個道具要什麼材料、怎麼製作：\(ItemQuery.Usage.recipe.label)
        - 描述用途或效果，或跟道具無關：\(ItemQuery.Usage.unsupported.label)

        \(Key.keyword.rawValue)：句子裡的道具名稱，或玩家說名稱裡有的字。從句子原封不動照抄，不補全、不改寫。句子只有條件、沒提到道具名稱時不填；\(Key.usage.rawValue) 是\(ItemQuery.Usage.unsupported.label)時不填。

        範例：

        \(exampleText)
        """
    }()
}
