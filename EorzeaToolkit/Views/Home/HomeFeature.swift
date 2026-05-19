import SwiftUI

enum HomeFeature: CaseIterable, Identifiable {
    case itemSearch
    case treasureMap
    case relicWeapon
    case miniCactpot
    case skillRotation

    var id: Self { self }
    
    var hasArtwork: Bool { UIImage(named: assetName) != nil }

    var title: String {
        switch self {
        case .itemSearch:
            "道具搜尋"
        case .treasureMap:
            "藏寶圖"
        case .relicWeapon:
            "發光武器"
        case .miniCactpot:
            "仙人微彩"
        case .skillRotation:
            "技能循環"
        }
    }

    var subtitle: String {
        switch self {
        case .itemSearch:
            "查詢道具資料"
        case .treasureMap:
            "採集點與寶藏點"
        case .relicWeapon:
            "情報與進度追蹤"
        case .miniCactpot:
            "推算最佳選擇"
        case .skillRotation:
            "查看職業技能與循環參考"
        }
    }

    var systemImage: String {
        switch self {
        case .itemSearch:
            "magnifyingglass.circle"
        case .treasureMap:
            "map.circle"
        case .relicWeapon:
            "sparkles.square.filled.on.square"
        case .miniCactpot:
            "dice.fill"
        case .skillRotation:
            "bolt.circle"
        }
    }

    var assetName: String {
        switch self {
        case .itemSearch:
            "home_item_search"
        case .treasureMap:
            "home_treasure_map"
        case .relicWeapon:
            "home_relic_weapon"
        case .miniCactpot:
            "home_mini_cactpot"
        case .skillRotation:
            "home_skill_rotation"
        }
    }

    var accent: Color {
        switch self {
        case .itemSearch:
            HomeStyle.crystal
        case .treasureMap:
            HomeStyle.gold
        case .relicWeapon:
            HomeStyle.aetherBlue
        case .miniCactpot:
            HomeStyle.crimson
        case .skillRotation:
            HomeStyle.crystal
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .itemSearch:
            ItemSearchView()
        case .treasureMap:
            TreasureMapListView()
        case .relicWeapon:
            RelicWeaponListView()
        case .miniCactpot:
            MiniCactpotView()
        case .skillRotation:
            BattleJobListView()
        }
    }
}
