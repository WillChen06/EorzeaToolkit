import SwiftUI

struct HomeHeroBanner: View {
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
