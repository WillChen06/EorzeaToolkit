import Foundation
import FoundationModels

extension ItemDescriptionSearchEngine {
    /// The on-device model on iOS 26 and later. Earlier versions have no description search,
    /// and nothing else in the item search changes.
    static var live: ItemDescriptionSearchEngine {
        guard #available(iOS 26.0, *) else {
            return .unsupported
        }
        return ItemDescriptionSearchEngine(
            isSupported: true,
            availability: { ItemQueryModelStatus.current().descriptionSearchAvailability },
            makeParser: { vocabulary in
                let parser = ItemQueryParser(vocabulary: vocabulary)
                return ItemDescriptionParser(
                    parse: { try await parser.query(for: $0) },
                    prewarm: { parser.prewarm() }
                )
            }
        )
    }
}

@available(iOS 26.0, *)
extension ItemQueryModelStatus {
    /// The 「模型狀態」 table: Apple Intelligence turned off or the model still downloading keep
    /// the button and explain why; every other reason hides it.
    var descriptionSearchAvailability: ItemDescriptionSearchAvailability {
        switch self {
        case .available:
            return .available
        case .appleIntelligenceNotEnabled:
            return .appleIntelligenceNotEnabled
        case .modelNotReady:
            return .modelNotReady
        case .deviceNotEligible, .traditionalChineseNotSupported, .unavailable:
            return .unavailable
        }
    }
}
