import SwiftUI

struct HomeView: View {
    private let features = HomeFeature.allCases
    private let featureColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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
                    .fill(HomeStyle.parchmentLight.opacity(0.42))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(HomeStyle.gold.opacity(0.22), lineWidth: 1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
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
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
    }

    private var heroBanner: some View {
        HomeHeroBanner()
            .frame(maxWidth: .infinity)
            .frame(height: 204)
            .shadow(color: HomeStyle.shadow, radius: 14, y: 8)
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader

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

    private var sectionHeader: some View {
        HStack(spacing: 10) {
            HomeSectionRule()

            Text("功能")
                .font(.headline)
                .foregroundStyle(HomeStyle.ink)

            HomeSectionRule(flipped: true)
        }
    }
}

private struct HomeSectionRule: View {
    var flipped = false

    var body: some View {
        HStack(spacing: 4) {
            if flipped {
                diamond
                rule
            } else {
                rule
                diamond
            }
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(HomeStyle.gold.opacity(0.38))
            .frame(height: 1)
    }

    private var diamond: some View {
        Diamond()
            .fill(HomeStyle.gold.opacity(0.50))
            .frame(width: 5, height: 5)
    }
}
