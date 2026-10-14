import Foundation

/// The model's answer: whether the sentence searches, asks for a recipe or cannot be handled,
/// and the part of it that names an item. Every other condition comes from the sentence itself
/// (`ItemQueryMatcher`).
struct ItemQueryModelOutput: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case usage
        case keyword
    }

    var usage: String?
    var keyword: String?
}
