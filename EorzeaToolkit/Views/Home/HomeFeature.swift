import SwiftUI

enum HomeFeature: CaseIterable, Identifiable {
    case itemSearch
    case treasureMap
    case relicWeapon
    case miniCactpot
    case skillRotation

    var id: Self { self }

    var title: LocalizedStringKey {
        L10n.Home.featureTitle(self)
    }

    var titleText: String {
        L10n.Home.featureTitleText(self)
    }

    var subtitle: LocalizedStringKey {
        L10n.Home.featureSubtitle(self)
    }

    var subtitleText: String {
        L10n.Home.featureSubtitleText(self)
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

    var artworkImage: Image {
        switch self {
        case .itemSearch:
            Image(.homeItemSearch)
        case .treasureMap:
            Image(.homeTreasureMap)
        case .relicWeapon:
            Image(.homeRelicWeapon)
        case .miniCactpot:
            Image(.homeMiniCactpot)
        case .skillRotation:
            Image(.homeSkillRotation)
        }
    }

    var accent: Color {
        switch self {
        case .itemSearch:
            AppTheme.crystal
        case .treasureMap:
            AppTheme.gold
        case .relicWeapon:
            AppTheme.aetherBlue
        case .miniCactpot:
            AppTheme.crimson
        case .skillRotation:
            AppTheme.crystal
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
