import Foundation

/// Short names players use for a job, keyed by the item search filter's job abbreviations.
///
/// The abbreviation itself and the official name from items.json are recognised without being
/// listed here. The app's own filter labels are deliberately not nicknames.
enum ItemJobNicknames {
    static let all: [String: [String]] = [
        "DRK": ["暗騎", "黑騎"],
        "GNB": ["絕槍"],
        "WHM": ["白魔"],
        "AST": ["占星"],
        "DRG": ["龍騎"],
        "RPR": ["鐮刀"],
        "VPR": ["毒蛇"],
        "BRD": ["詩人"],
        "MCH": ["機工"],
        "BLM": ["黑魔"],
        "SMN": ["召喚"],
        "RDM": ["赤魔"],
        "PCT": ["繪靈"],
        "CRP": ["木工"],
        "BSM": ["鍛造", "鍛冶"],
        "ARM": ["甲冑"],
        "GSM": ["金工", "雕金"],
        "LTW": ["皮革", "製革"],
        "WVR": ["裁縫"],
        "ALC": ["鍊金"],
        "CUL": ["烹調", "廚師"],
        "MIN": ["採掘", "礦工"],
        "BTN": ["園藝"],
        "FSH": ["釣魚"]
    ]
}
