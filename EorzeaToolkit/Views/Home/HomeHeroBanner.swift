import SwiftUI

struct HomeHeroBanner: View {
    var body: some View {
        VStack(spacing: 0) {
            heroArtwork
                .frame(height: 118)

            VStack(alignment: .leading, spacing: 7) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(HomeStyle.bannerBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(HomeStyle.gold.opacity(0.55), lineWidth: 1)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(HomeStyle.gold.opacity(0.24), lineWidth: 1)
                    .padding(6)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Eorzea Toolkit，整理冒險途中會反覆打開的工具")
    }

    private var heroArtwork: some View {
        Group {
            if HomeArtworkAsset.exists(named: HomeArtworkAsset.heroBanner) {
                Image(HomeArtworkAsset.heroBanner)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderHeroArtwork
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HomeStyle.gold.opacity(0.18))
                .frame(height: 1)
        }
        .clipped()
    }

    private var placeholderHeroArtwork: some View {
        ZStack {
            HomeStyle.heroArtworkBackground

            GeometryReader { geometry in
                let size = geometry.size

                ZStack {
                    Circle()
                        .stroke(HomeStyle.gold.opacity(0.18), lineWidth: 1)
                        .frame(width: size.width * 0.56, height: size.width * 0.56)
                        .offset(x: size.width * 0.30, y: -size.height * 0.74)

                    Path { path in
                        path.move(to: CGPoint(x: -8, y: size.height * 0.86))
                        path.addLine(to: CGPoint(x: size.width * 0.20, y: size.height * 0.48))
                        path.addLine(to: CGPoint(x: size.width * 0.36, y: size.height * 0.67))
                        path.addLine(to: CGPoint(x: size.width * 0.54, y: size.height * 0.36))
                        path.addLine(to: CGPoint(x: size.width * 0.74, y: size.height * 0.64))
                        path.addLine(to: CGPoint(x: size.width + 8, y: size.height * 0.38))
                    }
                    .stroke(HomeStyle.gold.opacity(0.26), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))

                    HomeCrystalMark()
                        .frame(width: 64, height: 82)
                        .offset(x: size.width * 0.32, y: 2)
                }
            }
        }
    }
}
