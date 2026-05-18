import SwiftUI

struct MainTabView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

private struct HomeView: View {
    private let pairedFeatures: [[HomeFeature]] = [
        [.itemSearch, .treasureMap],
        [.relicWeapon, .miniCactpot]
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                heroBanner
                featureSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(HomeStyle.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eorzea Toolkit")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(HomeStyle.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text("冒險工具手冊")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(HomeStyle.mutedInk)
        }
        .accessibilityElement(children: .combine)
    }

    private var heroBanner: some View {
        AsyncImage(url: HomeFeature.heroImageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 140)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                HomePlaceholderImage(systemImage: "sparkles", tint: HomeStyle.crystal)
            @unknown default:
                HomePlaceholderImage(systemImage: "sparkles", tint: HomeStyle.crystal)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(HomeStyle.gold.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: HomeStyle.shadow, radius: 14, y: 8)
        .accessibilityHidden(true)
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("功能")
                .font(.headline)
                .foregroundStyle(HomeStyle.ink)

            VStack(spacing: 12) {
                ForEach(pairedFeatures, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row) { feature in
                            NavigationLink {
                                feature.destination
                            } label: {
                                HomeFeatureCard(feature: feature)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                NavigationLink {
                    HomeFeature.skillRotation.destination
                } label: {
                    HomeFeatureCard(feature: .skillRotation, style: .wide)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private enum HomeFeature: CaseIterable, Identifiable {
    case itemSearch
    case treasureMap
    case relicWeapon
    case miniCactpot
    case skillRotation

    static let heroImageURL = URL(string: "https://placehold.co/1200x420/efe3c4/5b4630?text=Eorzea+Toolkit")

    var id: Self { self }

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
            "查詢道具資料、來源與相關資訊"
        case .treasureMap:
            "查看藏寶圖位置與地點提示"
        case .relicWeapon:
            "追蹤發光武器資料與製作階段"
        case .miniCactpot:
            "輔助推算仙人微彩最佳選擇"
        case .skillRotation:
            "查看職業技能與循環參考"
        }
    }

    var systemImage: String {
        switch self {
        case .itemSearch:
            "magnifyingglass"
        case .treasureMap:
            "map"
        case .relicWeapon:
            "sparkles"
        case .miniCactpot:
            "dice"
        case .skillRotation:
            "bolt.circle"
        }
    }

    var imageURL: URL? {
        switch self {
        case .itemSearch:
            URL(string: "https://placehold.co/420x260/f8efdb/6c5632?text=Item")
        case .treasureMap:
            URL(string: "https://placehold.co/420x260/f8efdb/6c5632?text=Map")
        case .relicWeapon:
            URL(string: "https://placehold.co/420x260/f8efdb/6c5632?text=Weapon")
        case .miniCactpot:
            URL(string: "https://placehold.co/420x260/f8efdb/6c5632?text=Cactpot")
        case .skillRotation:
            URL(string: "https://placehold.co/720x260/f8efdb/6c5632?text=Rotation")
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

private struct HomeFeatureCard: View {
    enum Style {
        case standard
        case wide
    }

    let feature: HomeFeature
    var style: Style = .standard

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardLayout
            case .wide:
                wideLayout
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeStyle.cardBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(HomeStyle.gold.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: HomeStyle.shadow.opacity(0.55), radius: 10, y: 5)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title)，\(feature.subtitle)")
    }

    private var standardLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureImage
                .frame(height: 86)

            VStack(alignment: .leading, spacing: 5) {
                featureTitle
                featureSubtitle
            }

            Spacer(minLength: 0)

            chevron
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(minHeight: 208, alignment: .top)
    }

    private var wideLayout: some View {
        HStack(spacing: 12) {
            featureImage
                .frame(width: 96, height: 88)

            VStack(alignment: .leading, spacing: 6) {
                featureTitle
                featureSubtitle
            }

            Spacer(minLength: 8)
            chevron
        }
        .frame(minHeight: 104, alignment: .center)
    }

    private var featureImage: some View {
        AsyncImage(url: feature.imageURL) { phase in
            switch phase {
            case .empty:
                HomePlaceholderImage(systemImage: feature.systemImage, tint: HomeStyle.gold)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                HomePlaceholderImage(systemImage: feature.systemImage, tint: HomeStyle.gold)
            @unknown default:
                HomePlaceholderImage(systemImage: feature.systemImage, tint: HomeStyle.gold)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(HomeStyle.gold.opacity(0.3), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var featureTitle: some View {
        Text(feature.title)
            .font(.headline)
            .foregroundStyle(HomeStyle.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }

    private var featureSubtitle: some View {
        Text(feature.subtitle)
            .font(.caption)
            .foregroundStyle(HomeStyle.mutedInk)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(HomeStyle.gold)
            .accessibilityHidden(true)
    }
}

private struct HomePlaceholderImage: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        ZStack {
            HomeStyle.placeholderBackground

            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

private enum HomeStyle {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.92, blue: 0.82),
            Color(red: 0.88, green: 0.80, blue: 0.64)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let cardBackground = Color(red: 0.99, green: 0.96, blue: 0.88)
    static let placeholderBackground = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.93, blue: 0.78),
            Color(red: 0.90, green: 0.82, blue: 0.64)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ink = Color(red: 0.22, green: 0.18, blue: 0.12)
    static let mutedInk = Color(red: 0.42, green: 0.34, blue: 0.23)
    static let gold = Color(red: 0.62, green: 0.47, blue: 0.22)
    static let crystal = Color(red: 0.20, green: 0.55, blue: 0.68)
    static let shadow = Color(red: 0.20, green: 0.14, blue: 0.06).opacity(0.18)
}

#Preview {
    MainTabView()
}
