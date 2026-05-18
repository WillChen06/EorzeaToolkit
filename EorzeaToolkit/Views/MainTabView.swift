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
        HomeHeroBanner()
        .frame(maxWidth: .infinity)
        .frame(height: 168)
        .shadow(color: HomeStyle.shadow, radius: 14, y: 8)
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("功能")
                    .font(.headline)
                    .foregroundStyle(HomeStyle.ink)

                Spacer()

                Text("5 個工具")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HomeStyle.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(HomeStyle.gold.opacity(0.12), in: Capsule())
            }

            VStack(spacing: 12) {
                ForEach(Array(pairedFeatures.enumerated()), id: \.offset) { _, row in
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
        HStack(spacing: 6) {
            featureImage
                .frame(width: 58, height: 84)

            VStack(alignment: .leading, spacing: 5) {
                featureTitle
                featureSubtitle
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(minHeight: 112, alignment: .center)
    }

    private var wideLayout: some View {
        HStack(spacing: 8) {
            featureImage
                .frame(width: 72, height: 88)

            VStack(alignment: .leading, spacing: 6) {
                featureTitle
                featureSubtitle
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(minHeight: 104, alignment: .center)
    }

    private var featureImage: some View {
        HomeFeatureArtwork(feature: feature)
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

}

private struct HomeHeroBanner: View {
    var body: some View {
        ZStack {
            HomeStyle.bannerBackground

            GeometryReader { geometry in
                let size = geometry.size

                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: size.height * 0.78))
                        path.addLine(to: CGPoint(x: size.width * 0.22, y: size.height * 0.45))
                        path.addLine(to: CGPoint(x: size.width * 0.36, y: size.height * 0.66))
                        path.addLine(to: CGPoint(x: size.width * 0.56, y: size.height * 0.34))
                        path.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.63))
                        path.addLine(to: CGPoint(x: size.width, y: size.height * 0.40))
                    }
                    .stroke(HomeStyle.gold.opacity(0.22), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))

                    Circle()
                        .stroke(HomeStyle.gold.opacity(0.16), lineWidth: 1)
                        .frame(width: size.width * 0.54, height: size.width * 0.54)
                        .offset(x: size.width * 0.34, y: -size.height * 0.58)

                    HomeCrystalMark()
                        .frame(width: 72, height: 92)
                        .offset(x: size.width * 0.30, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Eorzea Toolkit")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(HomeStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("整理冒險途中會反覆打開的工具")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(HomeStyle.mutedInk)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(HomeStyle.gold.opacity(0.55), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Eorzea Toolkit，整理冒險途中會反覆打開的工具")
    }
}

private struct HomeFeatureArtwork: View {
    let feature: HomeFeature

    var body: some View {
        ZStack {
            HomeStyle.placeholderBackground

            Circle()
                .fill(feature.accent.opacity(0.12))
                .frame(width: 64, height: 64)

            Circle()
                .strokeBorder(HomeStyle.gold.opacity(0.35), lineWidth: 1)
                .frame(width: 58, height: 58)

            Image(systemName: feature.systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(feature.accent)

            VStack {
                Spacer()

                Rectangle()
                    .fill(HomeStyle.gold.opacity(0.18))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
    }
}

private struct HomeCrystalMark: View {
    var body: some View {
        ZStack {
            Diamond()
                .fill(HomeStyle.crystal.opacity(0.20))
                .blur(radius: 6)

            Diamond()
                .fill(
                    LinearGradient(
                        colors: [
                            HomeStyle.crystal.opacity(0.95),
                            HomeStyle.aetherBlue.opacity(0.72)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    Diamond()
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                }

            Diamond()
                .stroke(HomeStyle.gold.opacity(0.55), lineWidth: 1)
                .scaleEffect(1.18)
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private enum HomeStyle {
    static let background = LinearGradient(
        colors: [
            parchmentTop,
            parchmentBottom
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let bannerBackground = LinearGradient(
        colors: [
            parchmentLight,
            parchmentTop,
            parchmentBottom
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let placeholderBackground = LinearGradient(
        colors: [
            parchmentLight,
            parchmentTop
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackground = dynamicColor(
        light: UIColor(red: 0.99, green: 0.96, blue: 0.88, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.20, blue: 0.15, alpha: 1)
    )
    static let parchmentLight = dynamicColor(
        light: UIColor(red: 0.99, green: 0.96, blue: 0.86, alpha: 1),
        dark: UIColor(red: 0.30, green: 0.25, blue: 0.18, alpha: 1)
    )
    static let parchmentTop = dynamicColor(
        light: UIColor(red: 0.96, green: 0.92, blue: 0.82, alpha: 1),
        dark: UIColor(red: 0.18, green: 0.16, blue: 0.13, alpha: 1)
    )
    static let parchmentBottom = dynamicColor(
        light: UIColor(red: 0.88, green: 0.80, blue: 0.64, alpha: 1),
        dark: UIColor(red: 0.12, green: 0.11, blue: 0.09, alpha: 1)
    )
    static let ink = dynamicColor(
        light: UIColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 1),
        dark: UIColor(red: 0.93, green: 0.87, blue: 0.74, alpha: 1)
    )
    static let mutedInk = dynamicColor(
        light: UIColor(red: 0.42, green: 0.34, blue: 0.23, alpha: 1),
        dark: UIColor(red: 0.76, green: 0.68, blue: 0.54, alpha: 1)
    )
    static let gold = dynamicColor(
        light: UIColor(red: 0.62, green: 0.47, blue: 0.22, alpha: 1),
        dark: UIColor(red: 0.78, green: 0.62, blue: 0.34, alpha: 1)
    )
    static let crystal = dynamicColor(
        light: UIColor(red: 0.20, green: 0.55, blue: 0.68, alpha: 1),
        dark: UIColor(red: 0.42, green: 0.78, blue: 0.88, alpha: 1)
    )
    static let aetherBlue = dynamicColor(
        light: UIColor(red: 0.26, green: 0.36, blue: 0.64, alpha: 1),
        dark: UIColor(red: 0.48, green: 0.58, blue: 0.88, alpha: 1)
    )
    static let crimson = dynamicColor(
        light: UIColor(red: 0.58, green: 0.22, blue: 0.18, alpha: 1),
        dark: UIColor(red: 0.86, green: 0.42, blue: 0.36, alpha: 1)
    )
    static let shadow = dynamicColor(
        light: UIColor(red: 0.20, green: 0.14, blue: 0.06, alpha: 0.18),
        dark: UIColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 0.32)
    )

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}

#Preview {
    MainTabView()
}
