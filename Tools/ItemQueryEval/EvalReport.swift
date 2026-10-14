import Foundation

/// The text the tool prints. Apart from the environment, date and timing lines, the same model
/// and evaluation set always print the same report, so two runs can be diffed.
enum EvalReport {
    static func composition(_ cases: [EvalCase]) -> String {
        let groups = EvalGroup.allCases
            .map { group in "\(group.title) \(cases.filter { $0.group == group }.count)" }
            .joined(separator: "、")
        return "評估集：\(cases.count) 句（\(groups)）"
    }

    static func unavailableMessage(_ status: ItemQueryModelStatus) -> String {
        let reason: String
        switch status {
        case .available:
            reason = "模型可以使用。"
        case .appleIntelligenceNotEnabled:
            reason = "Apple Intelligence 沒有開啟。到「系統設定」開啟 Apple Intelligence 後再試。"
        case .deviceNotEligible:
            reason = "這台裝置不支援 Apple Intelligence。"
        case .modelNotReady:
            reason = "模型還沒準備好，可能還在下載，稍後再試。"
        case .traditionalChineseNotSupported:
            reason = "裝置上的模型不支援繁體中文。"
        case .unavailable:
            reason = "模型目前無法使用。"
        }
        return "無法評估：\(reason)"
    }

    static func text(outcomes: [EvalOutcome], vocabulary: ItemQueryVocabulary) -> String {
        var lines: [String] = []
        let scores = FieldScore.scores(for: outcomes)

        lines.append("道具搜尋解析評估")
        lines.append("環境：\(ProcessInfo.processInfo.operatingSystemVersionString)")
        lines.append("日期：\(timestamp())")
        lines.append(composition(outcomes.map(\.evalCase)))
        lines.append("")

        lines.append("各欄位正確率（只算預期或實際有值的句子；被擋下或出錯的句子，每個欄位都算錯）")
        for score in scores {
            lines.append("  \(pad(score.field.title, 6))\(fraction(score.correct, score.total))\(verdict(score))")
        }
        let fullMatches = outcomes.filter(\.isFullMatch).count
        lines.append("  \(pad("整句完全正確", 6))\(fraction(fullMatches, outcomes.count))")
        lines.append("")

        let missed = scores.filter { $0.meetsThreshold == false }
        if missed.isEmpty {
            lines.append("門檻（用法、關鍵字 ≥ 90%，其他欄位 ≥ 85%）：達到")
        } else {
            let names = missed.map(\.field.title).joined(separator: "、")
            lines.append("門檻（用法、關鍵字 ≥ 90%，其他欄位 ≥ 85%）：未達到（\(names)）")
        }
        lines.append("")

        let blocked = outcomes.filter { if case .blocked = $0.result { return true } else { return false } }
        let failed = outcomes.filter { if case .failed = $0.result { return true } else { return false } }
        lines.append("被 guardrail 擋下：\(blocked.count) 句")
        lines += blocked.map { "  \(label($0.evalCase))" }
        lines.append("其他錯誤：\(failed.count) 句")
        for outcome in failed {
            lines.append("  \(label(outcome.evalCase))")
            if case .failed(let message) = outcome.result {
                lines.append("    \(message)")
            }
        }

        let seconds = outcomes.map(\.seconds)
        let average = seconds.isEmpty ? 0 : seconds.reduce(0, +) / Double(seconds.count)
        lines.append("平均耗時：\(String(format: "%.2f", average)) 秒（只供參考，Mac 的速度不代表手機）")
        lines.append("")

        let wrong = outcomes.filter { $0.actual != nil && !$0.isFullMatch }
        lines.append("解析錯誤的句子：\(wrong.count) 句")
        for outcome in wrong {
            guard let actual = outcome.actual else {
                continue
            }
            lines.append(label(outcome.evalCase))
            for field in EvalField.allCases where !field.matches(outcome.expected, actual) {
                let expectedText = field.text(outcome.expected, vocabulary: vocabulary)
                let actualText = field.text(actual, vocabulary: vocabulary)
                lines.append("  \(field.title)：預期 \(expectedText)｜實際 \(actualText)")
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func label(_ evalCase: EvalCase) -> String {
        "[\(evalCase.id)] \(evalCase.query)"
    }

    private static func fraction(_ correct: Int, _ total: Int) -> String {
        guard total > 0 else {
            return "—（沒有句子）"
        }
        let percent = String(format: "%.1f%%", Double(correct) / Double(total) * 100)
        return "\(correct)/\(total)  \(percent)"
    }

    private static func verdict(_ score: FieldScore) -> String {
        guard let meets = score.meetsThreshold else {
            return ""
        }
        let threshold = Int((score.field.threshold * 100).rounded())
        return "  門檻 \(threshold)% \(meets ? "達到" : "未達到")"
    }

    /// Pads a title with full-width spaces so the numbers line up in a terminal.
    private static func pad(_ title: String, _ width: Int) -> String {
        title + String(repeating: "　", count: max(0, width - title.count)) + "  "
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }
}
