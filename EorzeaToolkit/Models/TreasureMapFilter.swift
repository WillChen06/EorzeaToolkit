import Foundation

enum TreasureMapSortDirection: Equatable {
    case ascending
    case descending

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

struct TreasureMapFilter: Equatable {
    var selectedMajorVersions: Set<Int> = []
    var selectedLevels: Set<Int> = []

    var isActive: Bool {
        !selectedMajorVersions.isEmpty || !selectedLevels.isEmpty
    }

    var activeFilterCount: Int {
        selectedMajorVersions.count + selectedLevels.count
    }
}

enum TreasureMapQuery {
    static func versionOptions(from maps: [TreasureMap]) -> [Int] {
        Array(Set(maps.compactMap(\.expansionMajorVersion))).sorted()
    }

    static func levelOptions(from maps: [TreasureMap]) -> [Int] {
        Array(Set(maps.map(\.level))).sorted()
    }

    static func filtered(_ maps: [TreasureMap], by filter: TreasureMapFilter) -> [TreasureMap] {
        maps.filter { map in
            let matchesVersion = filter.selectedMajorVersions.isEmpty ||
                map.expansionMajorVersion.map(filter.selectedMajorVersions.contains) == true
            let matchesLevel = filter.selectedLevels.isEmpty || filter.selectedLevels.contains(map.level)

            return matchesVersion && matchesLevel
        }
    }

    static func sorted(_ maps: [TreasureMap], direction: TreasureMapSortDirection) -> [TreasureMap] {
        maps.enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element.gradeNumber, rhs.element.gradeNumber) {
                case let (left?, right?) where left != right:
                    return direction == .ascending ? left < right : left > right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }
}
