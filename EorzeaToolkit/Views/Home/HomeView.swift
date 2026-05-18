import SwiftUI

struct HomeView: View {
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
