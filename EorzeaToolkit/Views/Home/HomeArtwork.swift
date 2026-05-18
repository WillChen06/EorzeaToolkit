import SwiftUI

struct HomeFeatureArtwork: View {
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
