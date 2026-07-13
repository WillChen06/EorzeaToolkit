import SwiftUI

enum HomeArtworkAsset {
    static let heroAspectRatio: CGFloat = 3.0
    static let featureAspectRatio: CGFloat = 2.0 / 3.0
}

struct HomeFeatureArtwork: View {
    let feature: HomeFeature

    var body: some View {
        feature.artworkImage
            .resizable()
            .scaledToFill()
    }
}
