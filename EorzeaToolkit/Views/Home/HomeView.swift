import SwiftUI

struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var minimumCardWidth: CGFloat = 170

    private let features = HomeFeature.allCases
    private var featureColumns: [GridItem] {
        [GridItem(
            dynamicTypeSize.isAccessibilitySize ? .flexible() : .adaptive(minimum: max(170, minimumCardWidth)),
            spacing: 12
        )]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                heroBanner
                featureSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 32)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.parchmentLight.opacity(0.42))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(AppTheme.gold.opacity(0.22), lineWidth: 1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .appThemedBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Text(L10n.Home.appTitle)
            .font(.system(.largeTitle, design: .serif, weight: .semibold))
            .foregroundStyle(AppTheme.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var heroBanner: some View {
        HomeHeroBanner()
            .frame(maxWidth: .infinity)
            .shadow(color: AppTheme.shadow, radius: 14, y: 8)
    }

    private var featureSection: some View {
        LazyVGrid(columns: featureColumns, spacing: 12) {
            ForEach(features) { feature in
                NavigationLink {
                    feature.destination
                } label: {
                    HomeFeatureCard(feature: feature)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Narrow", traits: .fixedLayout(width: 320, height: 678)) {
    HomeView()
}

#Preview("Phone", traits: .fixedLayout(width: 393, height: 852)) {
    HomeView()
}

#Preview("Expanded", traits: .fixedLayout(width: 951, height: 669)) {
    HomeView()
}

#Preview("Accessibility", traits: .fixedLayout(width: 393, height: 852)) {
    HomeView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
