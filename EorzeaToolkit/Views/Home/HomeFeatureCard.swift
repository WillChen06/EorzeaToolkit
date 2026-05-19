import SwiftUI

struct HomeFeatureCard: View {
    let feature: HomeFeature

    var body: some View {
        cardLayout
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeStyle.cardBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(HomeStyle.cardDepthBackground)
                .offset(y: 2)
        }
        .overlay {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(HomeStyle.gold.opacity(0.44), lineWidth: 1)

                CardCornerOrnaments()
                    .stroke(HomeStyle.gold.opacity(0.34), lineWidth: 1)
                    .padding(6)
            }
        }
        .shadow(color: HomeStyle.shadow.opacity(0.55), radius: 10, y: 5)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title)，\(feature.subtitle)")
    }

    private var cardLayout: some View {
        HStack(spacing: 14) {
            featureImage
                .frame(width: 48, height: 72)
                .padding(.leading, 6)

            VStack(alignment: .leading, spacing: 5) {
                featureTitle
                featureSubtitle
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(minHeight: 96, alignment: .center)
    }

    private var featureImage: some View {
        HomeFeatureArtwork(feature: feature)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(HomeStyle.gold.opacity(0.34), lineWidth: 1)
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

private struct CardCornerOrnaments: Shape {
    func path(in rect: CGRect) -> Path {
        let inset: CGFloat = 3
        let length = min(rect.width, rect.height) * 0.16

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY + inset))

        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + length))

        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY - inset))

        path.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - length))
        return path
    }
}
