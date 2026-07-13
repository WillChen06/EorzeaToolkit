import Foundation

struct GatheringDataResponse: Decodable, Sendable {
    let gathering: [String: [ItemGatheringNode]]
}

struct ItemGatheringNode: Decodable, Hashable, Sendable {
    let job: String
    let method: String
    let level: Int
    let zoneID: Int
    let zoneName: String
    let x: Double
    let y: Double
    let mapID: Int
    let isHidden: Bool
    let isLegendary: Bool
    let isEphemeral: Bool
    let isLimited: Bool
    let spawns: [Int]
    let duration: Int

    enum CodingKeys: String, CodingKey {
        case job, method, level, x, y, spawns, duration
        case zoneID = "zone_id"
        case zoneName = "zone_name"
        case mapID = "map_id"
        case isHidden = "is_hidden"
        case isLegendary = "is_legendary"
        case isEphemeral = "is_ephemeral"
        case isLimited = "is_limited"
    }

    var locationText: String {
        let name = zoneName.isEmpty ? "未知地點" : zoneName
        return "\(name) (\(x.formattedCoordinate), \(y.formattedCoordinate))"
    }

    var traitLabels: [String] {
        var labels: [String] = []

        if isLegendary {
            labels.append("傳說")
        }

        if isEphemeral {
            labels.append("時限")
        }

        if isHidden {
            labels.append("隱藏")
        }

        return labels
    }

    var spawnTimeText: String? {
        guard (isLimited || isEphemeral), !spawns.isEmpty else {
            return nil
        }

        let ranges = spawns
            .sorted()
            .map { spawn in
                "\(Self.formatET(hour: spawn, minute: 0)) ~ \(Self.formatETEnd(from: spawn, duration: duration))"
            }

        return "ET " + ranges.joined(separator: "、")
    }

    private static func formatETEnd(from hour: Int, duration: Int) -> String {
        let startMinutes = hour * 60
        let endMinutes = Self.positiveModulo(startMinutes + duration, 24 * 60)
        return formatET(hour: endMinutes / 60, minute: endMinutes % 60)
    }

    private static func formatET(hour: Int, minute: Int) -> String {
        "\(positiveModulo(hour, 24)):" + String(format: "%02d", minute)
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

extension Double {
    var formattedCoordinate: String {
        String(format: "%.1f", self)
    }
}
