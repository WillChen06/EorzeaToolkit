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

/// The schema the model fills in: the fields of `ItemQueryFields`, with categories, body parts,
/// jobs and rarities limited to the vocabulary's names and levels to their bounds.
@available(iOS 26.0, macOS 26.0, *)
enum ItemQuerySchema {
    static func make(for vocabulary: ItemQueryVocabulary) throws -> GenerationSchema {
        typealias Key = ItemQueryFields.CodingKeys

        func choice(_ name: String, _ values: [String]) -> DynamicGenerationSchema {
            DynamicGenerationSchema(name: name, description: nil, anyOf: values)
        }

        func choices(_ name: String, _ values: [String]) -> DynamicGenerationSchema {
            DynamicGenerationSchema(arrayOf: choice(name, values), minimumElements: nil, maximumElements: nil)
        }

        func level(_ bounds: ClosedRange<Int>) -> DynamicGenerationSchema {
            DynamicGenerationSchema(type: Int.self, guides: [.range(bounds)])
        }

        func property(
            _ key: Key,
            _ schema: DynamicGenerationSchema,
            isOptional: Bool = true
        ) -> DynamicGenerationSchema.Property {
            DynamicGenerationSchema.Property(name: key.rawValue, description: nil, schema: schema, isOptional: isOptional)
        }

        let hq = ItemQueryVocabulary.hqLabels
        let tradable = ItemQueryVocabulary.tradableLabels

        let root = DynamicGenerationSchema(
            name: "ItemQuery",
            description: nil,
            properties: [
                property(.usage, choice("Usage", ItemQuery.Usage.allCases.map(\.label)), isOptional: false),
                property(.keyword, DynamicGenerationSchema(type: String.self, guides: [])),
                property(.categories, choices("Category", vocabulary.categories.map(\.name))),
                property(.slots, choices("Slot", vocabulary.slots.map(\.name))),
                property(.jobs, choices("Job", vocabulary.jobs.map(\.choice))),
                property(.equipLevelMin, level(ItemQuery.equipLevelBounds)),
                property(.equipLevelMax, level(ItemQuery.equipLevelBounds)),
                property(.itemLevelMin, level(ItemQuery.itemLevelBounds)),
                property(.itemLevelMax, level(ItemQuery.itemLevelBounds)),
                property(.rarities, choices("Rarity", ItemQueryVocabulary.rarities.map(\.name))),
                property(.hq, choice("HQ", [hq.yes, hq.no])),
                property(.tradable, choice("Tradable", [tradable.yes, tradable.no]))
            ]
        )
        return try GenerationSchema(root: root, dependencies: [])
    }
}

/// Turns one sentence into item query fields with the on-device model.
@available(iOS 26.0, macOS 26.0, *)
struct ItemQueryParser: Sendable {
    let vocabulary: ItemQueryVocabulary
    private let schema: GenerationSchema
    private let instructions: String

    init(vocabulary: ItemQueryVocabulary) throws {
        self.vocabulary = vocabulary
        self.schema = try ItemQuerySchema.make(for: vocabulary)
        self.instructions = ItemQueryInstructions.text(for: vocabulary)
    }

    /// Asks the model in a new session with greedy sampling, so the same sentence on the same
    /// model always yields the same fields and no earlier sentence influences the answer.
    func fields(for sentence: String) async throws -> ItemQueryFields {
        let session = LanguageModelSession(model: .default, tools: [], instructions: instructions)
        let response = try await session.respond(
            to: sentence,
            schema: schema,
            includeSchemaInPrompt: true,
            options: GenerationOptions(sampling: .greedy)
        )
        return try JSONDecoder().decode(ItemQueryFields.self, from: Data(response.content.jsonString.utf8))
    }

    func query(for sentence: String) async throws -> ItemQuery {
        let fields = try await self.fields(for: sentence)
        return vocabulary.resolve(fields)
    }

    /// Whether the model declined the sentence because of its safety guardrails, as opposed to
    /// failing for another reason.
    static func isGuardrailViolation(_ error: Error) -> Bool {
        guard let error = error as? LanguageModelSession.GenerationError else {
            return false
        }
        if case .guardrailViolation = error {
            return true
        }
        return false
    }
}
