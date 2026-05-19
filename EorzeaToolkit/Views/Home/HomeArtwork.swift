import SwiftUI

enum HomeArtworkAsset {
    static let heroBanner = "home_hero_banner"

    static func exists(named assetName: String) -> Bool {
        UIImage(named: assetName) != nil
    }
}

struct HomeFeatureArtwork: View {
    let feature: HomeFeature

    var body: some View {
        if HomeArtworkAsset.exists(named: feature.assetName) {
            Image(feature.assetName)
                .resizable()
                .scaledToFill()
        } else {
            placeholderArtwork
        }
    }

    private var placeholderArtwork: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            ZStack {
                HomeStyle.artworkBackground

                Circle()
                    .fill(feature.accent.opacity(0.10))
                    .frame(width: side * 0.82, height: side * 0.82)

                Circle()
                    .strokeBorder(HomeStyle.gold.opacity(0.34), lineWidth: 1)
                    .frame(width: side * 0.72, height: side * 0.72)

                Diamond()
                    .stroke(HomeStyle.gold.opacity(0.22), lineWidth: 1)
                    .frame(width: side * 0.78, height: side * 0.78)

                Image(systemName: feature.systemImage)
                    .font(.system(size: side * 0.34, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(feature.accent)

                VStack {
                    Spacer()

                    Rectangle()
                        .fill(HomeStyle.gold.opacity(0.18))
                        .frame(height: 1)
                        .padding(.horizontal, max(10, geometry.size.width * 0.20))
                        .padding(.bottom, 8)
                }
            }
        }
    }
}

struct HomeCrystalMark: View {
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

struct Diamond: Shape {
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
