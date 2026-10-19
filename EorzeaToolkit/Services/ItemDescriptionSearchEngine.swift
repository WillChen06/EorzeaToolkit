import Foundation

/// Whether the item search can offer description search, as the 「模型狀態」 table of
/// prompts/item-description-search.md puts it. It names no FoundationModels type, so the item
/// search keeps it on every iOS version.
enum ItemDescriptionSearchAvailability: Equatable, Sendable, CaseIterable {
    case available
    case appleIntelligenceNotEnabled
    case modelNotReady
    /// The device, its languages or the iOS version rule description search out.
    case unavailable

    /// Whether the item search shows the description search button.
    var showsButton: Bool {
        self != .unavailable
    }

    /// Whether the description search screen can search.
    var canSearch: Bool {
        self == .available
    }
}

/// Turns one sentence into an item query with the on-device model.
struct ItemDescriptionParser: Sendable {
    let parse: @Sendable (_ sentence: String) async throws -> ItemQuery
    /// Loads the model ahead of the first sentence.
    let prewarm: @Sendable () -> Void
}

/// The model behind description search, handed to the item search so that tests need neither
/// the model nor iOS 26. `live` is the on-device model, in
/// `ItemDescriptionSearchEngine+FoundationModels.swift`.
struct ItemDescriptionSearchEngine: Sendable {
    /// Whether this iOS version can run description search at all. Only then does the item
    /// search build the vocabulary a parser needs.
    let isSupported: Bool
    let availability: @Sendable () -> ItemDescriptionSearchAvailability
    let makeParser: @Sendable (ItemQueryVocabulary) -> ItemDescriptionParser

    /// No description search: before iOS 26, and in tests that do not ask for one.
    static let unsupported = ItemDescriptionSearchEngine(
        isSupported: false,
        availability: { .unavailable },
        makeParser: { _ in
            ItemDescriptionParser(parse: { _ in throw CancellationError() }, prewarm: {})
        }
    )
}
