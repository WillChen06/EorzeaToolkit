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

/// The schema the model fills in: the fields of `ItemQueryModelOutput`. The usage is one of
/// its three labels and the keyword is free text, checked against the sentence afterwards.
@available(iOS 26.0, macOS 26.0, *)
enum ItemQuerySchema {
    static func make() throws -> GenerationSchema {
        typealias Key = ItemQueryModelOutput.CodingKeys

        let usage = DynamicGenerationSchema(name: "Usage", description: nil, anyOf: ItemQuery.Usage.allCases.map(\.label))
        let keyword = DynamicGenerationSchema(type: String.self, guides: [])
        let root = DynamicGenerationSchema(
            name: "ItemQuery",
            description: nil,
            properties: [
                DynamicGenerationSchema.Property(name: Key.usage.rawValue, description: nil, schema: usage, isOptional: false),
                DynamicGenerationSchema.Property(name: Key.keyword.rawValue, description: nil, schema: keyword, isOptional: true)
            ]
        )
        return try GenerationSchema(root: root, dependencies: [])
    }
}

/// Turns one sentence into item query fields: the usage and keyword from the on-device model,
/// every other condition from the sentence.
@available(iOS 26.0, macOS 26.0, *)
struct ItemQueryParser: Sendable {
    let vocabulary: ItemQueryVocabulary
    private let matcher: ItemQueryMatcher
    private let schema: GenerationSchema

    init(vocabulary: ItemQueryVocabulary) throws {
        self.vocabulary = vocabulary
        self.matcher = ItemQueryMatcher(vocabulary: vocabulary)
        self.schema = try ItemQuerySchema.make()
    }

    /// Asks the model in a new session with greedy sampling, so the same sentence on the same
    /// model always yields the same answer and no earlier sentence influences it.
    func answer(for sentence: String) async throws -> ItemQueryModelOutput {
        let session = LanguageModelSession(model: .default, tools: [], instructions: ItemQueryInstructions.text)
        let response = try await session.respond(
            to: sentence,
            schema: schema,
            includeSchemaInPrompt: true,
            options: GenerationOptions(samplingMode: .greedy)
        )
        return try JSONDecoder().decode(ItemQueryModelOutput.self, from: Data(response.content.jsonString.utf8))
    }

    /// The model's usage and keyword, with the conditions the sentence states.
    func fields(for sentence: String, answer: ItemQueryModelOutput) -> ItemQueryFields {
        matcher.fields(for: sentence, usage: answer.usage, keyword: answer.keyword)
    }

    func fields(for sentence: String) async throws -> ItemQueryFields {
        let answer = try await self.answer(for: sentence)
        return fields(for: sentence, answer: answer)
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
