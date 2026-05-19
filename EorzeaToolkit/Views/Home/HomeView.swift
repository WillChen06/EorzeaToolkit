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
        Text("Eorzea Toolkit")
            .font(.system(.largeTitle, design: .serif, weight: .semibold))
            .foregroundStyle(HomeStyle.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var heroBanner: some View {
        HomeHeroBanner()
            .frame(maxWidth: .infinity)
            .frame(height: 118)
            .shadow(color: HomeStyle.shadow, radius: 14, y: 8)
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
