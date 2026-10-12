import Foundation

/// The version of an item data file, written by `scripts/build_data.py` as
/// `<game version>-r<revision>`, for example `2026.09.14.0000.0000-r1`.
///
/// Versions order by game version, then by revision. A string that does not have this exact
/// shape — such as `2026-05-17-v2`, the format used before the Traditional Chinese data — does
/// not parse, and counts as older than any version that does.
struct ItemDataVersion: Comparable, Sendable {
    let gameVersion: [Int]
    let revision: Int

    private static let gameVersionComponentCount = 5

    init?(_ string: String) {
        let parts = string.components(separatedBy: "-r")
        guard parts.count == 2, let revision = Self.number(parts[1]) else {
            return nil
        }

        let components = parts[0]
            .split(separator: ".", omittingEmptySubsequences: false)
            .map { Self.number(String($0)) }
        guard components.count == Self.gameVersionComponentCount else {
            return nil
        }

        let gameVersion = components.compactMap { $0 }
        guard gameVersion.count == components.count else {
            return nil
        }

        self.gameVersion = gameVersion
        self.revision = revision
    }

    static func < (lhs: ItemDataVersion, rhs: ItemDataVersion) -> Bool {
        if lhs.gameVersion != rhs.gameVersion {
            return lhs.gameVersion.lexicographicallyPrecedes(rhs.gameVersion)
        }
        return lhs.revision < rhs.revision
    }

    /// Whether `candidate` is strictly newer than `current`.
    ///
    /// A candidate that does not parse is never newer. A current version that is missing or does
    /// not parse is older than any candidate that does.
    static func isNewer(_ candidate: String?, than current: String?) -> Bool {
        guard let candidate = candidate.flatMap(ItemDataVersion.init) else {
            return false
        }
        guard let current = current.flatMap(ItemDataVersion.init) else {
            return true
        }
        return candidate > current
    }

    private static func number(_ text: String) -> Int? {
        guard !text.isEmpty, text.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return nil
        }
        return Int(text)
    }
}
