import Foundation

/// The jobs the item search can filter by, in the order the filter shows them.
///
/// Kept free of localization and UI types so the item query evaluation tool (macOS) compiles
/// the same list as the app. The localized `displayName` lives with the item search view model.
struct ItemJobFilterOption: Identifiable, Hashable, Sendable {
    let abbreviation: String
    let iconPath: String

    var id: String { abbreviation }

    var iconURL: URL? {
        XIVIconURL.make(from: iconPath)
    }

    static let displayOptions: [ItemJobFilterOption] = [
        ItemJobFilterOption(abbreviation: "PLD", iconPath: "062000/062119_hr1.tex"),
        ItemJobFilterOption(abbreviation: "WAR", iconPath: "062000/062121_hr1.tex"),
        ItemJobFilterOption(abbreviation: "DRK", iconPath: "062000/062132_hr1.tex"),
        ItemJobFilterOption(abbreviation: "GNB", iconPath: "062000/062137_hr1.tex"),
        ItemJobFilterOption(abbreviation: "WHM", iconPath: "062000/062124_hr1.tex"),
        ItemJobFilterOption(abbreviation: "SCH", iconPath: "062000/062128_hr1.tex"),
        ItemJobFilterOption(abbreviation: "AST", iconPath: "062000/062133_hr1.tex"),
        ItemJobFilterOption(abbreviation: "SGE", iconPath: "062000/062140_hr1.tex"),
        ItemJobFilterOption(abbreviation: "MNK", iconPath: "062000/062120_hr1.tex"),
        ItemJobFilterOption(abbreviation: "DRG", iconPath: "062000/062122_hr1.tex"),
        ItemJobFilterOption(abbreviation: "NIN", iconPath: "062000/062130_hr1.tex"),
        ItemJobFilterOption(abbreviation: "SAM", iconPath: "062000/062134_hr1.tex"),
        ItemJobFilterOption(abbreviation: "RPR", iconPath: "062000/062139_hr1.tex"),
        ItemJobFilterOption(abbreviation: "VPR", iconPath: "062000/062141_hr1.tex"),
        ItemJobFilterOption(abbreviation: "BRD", iconPath: "062000/062123_hr1.tex"),
        ItemJobFilterOption(abbreviation: "MCH", iconPath: "062000/062131_hr1.tex"),
        ItemJobFilterOption(abbreviation: "DNC", iconPath: "062000/062138_hr1.tex"),
        ItemJobFilterOption(abbreviation: "BLM", iconPath: "062000/062125_hr1.tex"),
        ItemJobFilterOption(abbreviation: "SMN", iconPath: "062000/062127_hr1.tex"),
        ItemJobFilterOption(abbreviation: "RDM", iconPath: "062000/062135_hr1.tex"),
        ItemJobFilterOption(abbreviation: "PCT", iconPath: "062000/062142_hr1.tex"),
        ItemJobFilterOption(abbreviation: "CRP", iconPath: "062000/062108_hr1.tex"),
        ItemJobFilterOption(abbreviation: "BSM", iconPath: "062000/062109_hr1.tex"),
        ItemJobFilterOption(abbreviation: "ARM", iconPath: "062000/062110_hr1.tex"),
        ItemJobFilterOption(abbreviation: "GSM", iconPath: "062000/062111_hr1.tex"),
        ItemJobFilterOption(abbreviation: "LTW", iconPath: "062000/062112_hr1.tex"),
        ItemJobFilterOption(abbreviation: "WVR", iconPath: "062000/062113_hr1.tex"),
        ItemJobFilterOption(abbreviation: "ALC", iconPath: "062000/062114_hr1.tex"),
        ItemJobFilterOption(abbreviation: "CUL", iconPath: "062000/062115_hr1.tex"),
        ItemJobFilterOption(abbreviation: "MIN", iconPath: "062000/062116_hr1.tex"),
        ItemJobFilterOption(abbreviation: "BTN", iconPath: "062000/062117_hr1.tex"),
        ItemJobFilterOption(abbreviation: "FSH", iconPath: "062000/062118_hr1.tex")
    ]
}
