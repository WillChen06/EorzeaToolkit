import Foundation

enum EvalGroup: String, Decodable, CaseIterable {
    case combination
    case equipLevel
    case itemLevel
    case recipe
    case guardrail
    case unsupported

    var title: String {
        switch self {
        case .combination: return "組合條件"
        case .equipLevel: return "裝備等級"
        case .itemLevel: return "品級"
        case .recipe: return "查配方"
        case .guardrail: return "可能被 guardrail 擋下的名稱"
        case .unsupported: return "無法處理"
        }
    }

    /// The spec's minimum number of cases in this group.
    var minimumCount: Int {
        switch self {
        case .combination: return 20
        case .equipLevel: return 5
        case .itemLevel: return 3
        case .recipe: return 5
        case .guardrail: return 5
        case .unsupported: return 3
        }
    }
}

/// One sentence of the evaluation set and the fields its parse should produce, written with the
/// vocabulary's names, as the parse result is before resolution.
struct EvalCase: Decodable {
    let id: String
    let group: EvalGroup
    let query: String
    let expected: ItemQueryFields
}

enum EvalCaseLoader {
    private static let caseKeys: Set<String> = ["id", "group", "query", "expected"]
    private static let expectedKeys = Set(ItemQueryFields.CodingKeys.allCases.map(\.rawValue))

    /// The sum of the groups' minimums.
    static var minimumTotal: Int {
        EvalGroup.allCases.reduce(0) { $0 + $1.minimumCount }
    }

    /// Decodes each case on its own, so a broken case is reported by its position and id rather
    /// than failing the whole file at once. Returns every problem found; the cases are usable
    /// only when there are none.
    static func load(from url: URL, vocabulary: ItemQueryVocabulary) -> (cases: [EvalCase], problems: [String]) {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return ([], ["讀不到評估集 \(url.path)：\(error.localizedDescription)"])
        }

        let root: Any
        do {
            root = try JSONSerialization.jsonObject(with: data)
        } catch {
            return ([], ["評估集不是有效的 JSON：\(describe(error))"])
        }
        guard let object = root as? [String: Any], let entries = object["cases"] as? [Any] else {
            return ([], ["評估集最外層要是 {\"cases\": [ … ]}"])
        }

        var cases: [EvalCase] = []
        var problems: [String] = []
        var seenIds = Set<String>()

        for (index, entry) in entries.enumerated() {
            let label = location(of: entry, at: index)
            guard let fields = entry as? [String: Any], JSONSerialization.isValidJSONObject(fields) else {
                problems.append("\(label)：每一句要是一個物件")
                continue
            }

            // The decoder ignores keys it does not know, so a misspelled field would silently
            // drop a condition from the expected result.
            for key in Set(fields.keys).subtracting(caseKeys).sorted() {
                problems.append("\(label)：不認得的欄位 \(key)")
            }
            if let expected = fields["expected"] as? [String: Any] {
                for key in Set(expected.keys).subtracting(expectedKeys).sorted() {
                    problems.append("\(label)：expected 裡不認得的欄位 \(key)")
                }
            }

            let evalCase: EvalCase
            do {
                let caseData = try JSONSerialization.data(withJSONObject: fields)
                evalCase = try JSONDecoder().decode(EvalCase.self, from: caseData)
            } catch {
                problems.append("\(label)：格式錯誤，\(describe(error))")
                continue
            }

            for message in validate(evalCase, vocabulary: vocabulary) {
                problems.append("\(label)：\(message)")
            }
            if !seenIds.insert(evalCase.id).inserted {
                problems.append("\(label)：編號重複")
            }
            cases.append(evalCase)
        }

        for group in EvalGroup.allCases {
            let count = cases.filter { $0.group == group }.count
            if count < group.minimumCount {
                problems.append("「\(group.title)」有 \(count) 句，至少要 \(group.minimumCount) 句")
            }
        }
        if cases.count < minimumTotal {
            problems.append("評估集有 \(cases.count) 句，至少要 \(minimumTotal) 句")
        }

        return (cases, problems)
    }

    /// Checks one case against the spec's rules. The model's own answers are never checked this
    /// way: resolution ignores unknown names, but an expected result must not contain any.
    static func validate(_ evalCase: EvalCase, vocabulary: ItemQueryVocabulary) -> [String] {
        var problems: [String] = []
        let expected = evalCase.expected

        if evalCase.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("沒有編號")
        }
        if evalCase.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("沒有原文")
        }

        if let usage = expected.usage {
            if ItemQuery.Usage(label: usage) == nil {
                let labels = ItemQuery.Usage.allCases.map(\.label).joined(separator: "／")
                problems.append("用法「\(usage)」不是 \(labels) 之一")
            }
        } else {
            problems.append("沒有用法")
        }

        if let keyword = expected.keyword, !evalCase.query.contains(keyword) {
            problems.append("關鍵字「\(keyword)」不在原文裡")
        }

        for name in expected.categories ?? [] where vocabulary.categoryIds(named: [name]).isEmpty {
            problems.append("分類「\(name)」不在 items.json 的分類裡")
        }
        for name in expected.slots ?? [] where vocabulary.equipSlotIds(named: [name]).isEmpty {
            problems.append("部位「\(name)」不是部位清單裡的名稱")
        }
        for name in expected.jobs ?? [] where vocabulary.jobAbbreviation(named: name) == nil {
            problems.append("職業「\(name)」不是職業 filter 的縮寫或名稱")
        }
        for name in expected.rarities ?? [] where vocabulary.rarityIds(named: [name]).isEmpty {
            problems.append("稀有度「\(name)」不是稀有度的名稱")
        }

        problems += flagProblems("HQ", expected.hq, labels: ItemQueryVocabulary.hqLabels)
        problems += flagProblems("可交易", expected.tradable, labels: ItemQueryVocabulary.tradableLabels)
        problems += levelProblems("裝備等級", expected.equipLevelMin, expected.equipLevelMax, bounds: ItemQuery.equipLevelBounds)
        problems += levelProblems("品級", expected.itemLevelMin, expected.itemLevelMax, bounds: ItemQuery.itemLevelBounds)

        return problems
    }

    private static func flagProblems(_ title: String, _ label: String?, labels: ItemQueryVocabulary.FlagLabels) -> [String] {
        guard let label, ItemQueryVocabulary.flag(label, labels: labels) == nil else {
            return []
        }
        return ["\(title)「\(label)」要是「\(labels.yes)」或「\(labels.no)」"]
    }

    private static func levelProblems(_ title: String, _ lower: Int?, _ upper: Int?, bounds: ClosedRange<Int>) -> [String] {
        var problems: [String] = []
        for value in [lower, upper].compactMap({ $0 }) where !bounds.contains(value) {
            problems.append("\(title) \(value) 不在 \(bounds.lowerBound)–\(bounds.upperBound) 之內")
        }
        if let lower, let upper, lower > upper {
            problems.append("\(title)下限 \(lower) 大於上限 \(upper)")
        }
        return problems
    }

    private static func location(of entry: Any, at index: Int) -> String {
        let fields = entry as? [String: Any]
        let id = fields?["id"] as? String ?? "?"
        let query = fields?["query"] as? String ?? ""
        return "第 \(index + 1) 句 \(id)「\(query)」"
    }

    private static func describe(_ error: Error) -> String {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                return "缺少欄位 \(path(context.codingPath + [key]))"
            case .typeMismatch(_, let context), .valueNotFound(_, let context):
                return "欄位 \(path(context.codingPath)) 的型別不對"
            case .dataCorrupted(let context):
                return "欄位 \(path(context.codingPath)) 的值不對：\(context.debugDescription)"
            @unknown default:
                return String(describing: error)
            }
        }
        let nsError = error as NSError
        return nsError.userInfo[NSDebugDescriptionErrorKey] as? String ?? error.localizedDescription
    }

    private static func path(_ codingPath: [CodingKey]) -> String {
        codingPath.map { key in key.intValue.map { "\($0)" } ?? key.stringValue }.joined(separator: ".")
    }
}
