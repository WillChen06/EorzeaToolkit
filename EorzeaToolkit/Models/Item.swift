import Foundation

struct ItemDataResponse: Codable, Sendable {
    let items: [Item]
}

struct Item: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let iconId: Int
    let iconPath: String
    let ilvl: Int
    let rarity: Int

    enum CodingKeys: String, CodingKey {
        case id, ilvl, rarity
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
    }

    var displayName: String {
        nameTw.isEmpty ? nameCn : nameTw
    }

    var iconURL: URL? {
        URL(string: "https://beta.xivapi.com/api/1/asset/ui/icon/\(iconPath)?format=png")
    }
}
