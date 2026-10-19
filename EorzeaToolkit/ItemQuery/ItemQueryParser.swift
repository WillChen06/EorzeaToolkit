import Foundation
import FoundationModels

/// Whether the on-device model can parse item queries right now.
@available(iOS 26.0, macOS 26.0, *)
enum ItemQueryModelStatus: Equatable, Sendable {
    case available
    case appleIntelligenceNotEnabled
    case deviceNotEligible
    case modelNotReady
    case traditionalChineseNotSupported
    case unavailable

    static func current(model: SystemLanguageModel = .default) -> ItemQueryModelStatus {
        if case .unavailable(let reason) = model.availability {
            switch reason {
            case .appleIntelligenceNotEnabled:
                return .appleIntelligenceNotEnabled
            case .deviceNotEligible:
                return .deviceNotEligible
            case .modelNotReady:
                return .modelNotReady
            @unknown default:
                return .unavailable
            }
        }

        let supportsTraditionalChinese = model.supportedLanguages.contains { language in
            language.languageCode == .chinese
                && Locale.Language(identifier: language.maximalIdentifier).script == .hanTraditional
        }
        return supportsTraditionalChinese ? .available : .traditionalChineseNotSupported
    }
}

/// Turns one sentence into item query fields: the usage and keyword from the on-device model,
/// every other condition from the sentence.
@available(iOS 26.0, macOS 26.0, *)
struct ItemQueryParser: Sendable {
    /// The model's answer had no usage it could be read for, which is also what a refusal
    /// message looks like.
    struct UnreadableAnswer: Error, CustomStringConvertible {
        let text: String

        var description: String {
            "模型沒有照格式回答：\(text)"
        }
    }

    let vocabulary: ItemQueryVocabulary
    private let matcher: ItemQueryMatcher
    /// Permissive guardrails, so that ordinary sentences such as 「品級690以上的頭部裝備」 are not
    /// blocked. They apply only to plain text answers, which is why the model answers in text.
    private let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)

    init(vocabulary: ItemQueryVocabulary) {
        self.vocabulary = vocabulary
        self.matcher = ItemQueryMatcher(vocabulary: vocabulary)
    }

    /// The model's plain text answer, asked in a new session with greedy sampling, so the same
    /// sentence on the same model always yields the same answer and no earlier sentence
    /// influences it.
    func answer(for sentence: String) async throws -> String {
        let session = LanguageModelSession(model: model, tools: [], instructions: ItemQueryInstructions.text)
        let response = try await session.respond(to: sentence, options: GenerationOptions(samplingMode: .greedy))
        return response.content
    }

    /// Loads the model and these instructions ahead of the first sentence, so that it answers
    /// sooner. Each sentence still gets a session of its own.
    func prewarm() {
        LanguageModelSession(model: model, tools: [], instructions: ItemQueryInstructions.text).prewarm()
    }

    /// The usage and keyword read from the model's answer, with the conditions the sentence
    /// states.
    func fields(for sentence: String, answer: String) throws -> ItemQueryFields {
        guard let output = ItemQueryModelOutput(text: answer) else {
            throw UnreadableAnswer(text: answer)
        }
        return matcher.fields(for: sentence, usage: output.usage, keyword: output.keyword)
    }

    func fields(for sentence: String) async throws -> ItemQueryFields {
        let answer = try await self.answer(for: sentence)
        return try fields(for: sentence, answer: answer)
    }

    func query(for sentence: String) async throws -> ItemQuery {
        let fields = try await self.fields(for: sentence)
        return vocabulary.resolve(fields)
    }

    /// Whether the model's safety guardrails declined the sentence or its answer, as opposed to
    /// failing for another reason. iOS and macOS 27 report this as `LanguageModelError`, earlier
    /// versions as `LanguageModelSession.GenerationError`.
    static func isGuardrailViolation(_ error: Error) -> Bool {
        if #available(iOS 27.0, macOS 27.0, *), let error = error as? LanguageModelError,
           case .guardrailViolation = error {
            return true
        }
        if let error = error as? LanguageModelSession.GenerationError, case .guardrailViolation = error {
            return true
        }
        return false
    }
}
