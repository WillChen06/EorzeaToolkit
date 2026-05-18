import SwiftUI

struct HomeFeatureCard: View {
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
