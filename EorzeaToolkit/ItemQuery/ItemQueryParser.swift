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

/// The schema the model fills in: the fields of `ItemQueryModelOutput`. Every condition is an
/// object whose quote comes first, so the model copies the supporting fragment before it picks
/// a value. Categories, body parts, jobs and rarities are limited to the vocabulary's names and
/// levels to their bounds.
@available(iOS 26.0, macOS 26.0, *)
enum ItemQuerySchema {
    static func make(for vocabulary: ItemQueryVocabulary) throws -> GenerationSchema {
        typealias Key = ItemQueryModelOutput.CodingKeys
        typealias Nested = ItemQueryModelOutput.NestedKey

        func field(
            _ name: String,
            _ schema: DynamicGenerationSchema,
            isOptional: Bool
        ) -> DynamicGenerationSchema.Property {
            DynamicGenerationSchema.Property(name: name, description: nil, schema: schema, isOptional: isOptional)
        }

        func text() -> DynamicGenerationSchema {
            DynamicGenerationSchema(type: String.self, guides: [])
        }

        func quoted(_ name: String, _ valueKey: Nested, _ value: DynamicGenerationSchema) -> DynamicGenerationSchema {
            DynamicGenerationSchema(name: name, description: nil, properties: [
                field(Nested.quote.rawValue, text(), isOptional: false),
                field(valueKey.rawValue, value, isOptional: false)
            ])
        }

        func choices(_ name: String, _ values: [String]) -> DynamicGenerationSchema {
            let value = DynamicGenerationSchema(name: name + "Name", description: nil, anyOf: values)
            return DynamicGenerationSchema(arrayOf: quoted(name, .name, value), minimumElements: nil, maximumElements: nil)
        }

        func flag(_ name: String, _ labels: ItemQueryVocabulary.FlagLabels) -> DynamicGenerationSchema {
            let value = DynamicGenerationSchema(name: name + "Value", description: nil, anyOf: [labels.yes, labels.no])
            return quoted(name, .value, value)
        }

        func levels(_ name: String, _ bounds: ClosedRange<Int>) -> DynamicGenerationSchema {
            let level = DynamicGenerationSchema(type: Int.self, guides: [.range(bounds)])
            return DynamicGenerationSchema(name: name, description: nil, properties: [
                field(Nested.quote.rawValue, text(), isOptional: false),
                field(Nested.min.rawValue, level, isOptional: true),
                field(Nested.max.rawValue, level, isOptional: true)
            ])
        }

        func property(_ key: Key, _ schema: DynamicGenerationSchema, isOptional: Bool = true) -> DynamicGenerationSchema.Property {
            field(key.rawValue, schema, isOptional: isOptional)
        }

        let usage = DynamicGenerationSchema(name: "Usage", description: nil, anyOf: ItemQuery.Usage.allCases.map(\.label))
        let root = DynamicGenerationSchema(
            name: "ItemQuery",
            description: nil,
            properties: [
                property(.usage, usage, isOptional: false),
                property(.keyword, text()),
                property(.categories, choices("Category", vocabulary.categories.map(\.name))),
                property(.slots, choices("Slot", vocabulary.slots.map(\.name))),
                property(.jobs, choices("Job", vocabulary.jobs.map(\.choice))),
                property(.equipLevel, levels("EquipLevel", ItemQuery.equipLevelBounds)),
                property(.itemLevel, levels("ItemLevel", ItemQuery.itemLevelBounds)),
                property(.rarities, choices("Rarity", ItemQueryVocabulary.rarities.map(\.name))),
                property(.hq, flag("HQ", ItemQueryVocabulary.hqLabels)),
                property(.tradable, flag("Tradable", ItemQueryVocabulary.tradableLabels))
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
    /// model always yields the same answer and no earlier sentence influences it.
    func answer(for sentence: String) async throws -> ItemQueryModelOutput {
        let session = LanguageModelSession(model: .default, tools: [], instructions: instructions)
        let response = try await session.respond(
            to: sentence,
            schema: schema,
            includeSchemaInPrompt: true,
            options: GenerationOptions(samplingMode: .greedy)
        )
        return try JSONDecoder().decode(ItemQueryModelOutput.self, from: Data(response.content.jsonString.utf8))
    }

    /// The model's answer, keeping only the conditions the sentence supports.
    func fields(for sentence: String) async throws -> ItemQueryFields {
        let answer = try await self.answer(for: sentence)
        return ItemQueryEvidence.fields(from: answer, sentence: sentence)
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
