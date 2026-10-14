import Foundation

/// Turns an icon path from the game data (for example `062000/062119_hr1.tex`) into its PNG URL
/// on XIVAPI.
enum XIVIconURL {
    static func make(from iconPath: String) -> URL? {
        let pngPath = iconPath
            .replacingOccurrences(of: "_hr1.tex", with: ".png")
            .replacingOccurrences(of: ".tex", with: ".png")

        return URL(string: "https://xivapi.com/i/\(pngPath)")
    }
}
