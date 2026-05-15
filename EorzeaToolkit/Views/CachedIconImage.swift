import Kingfisher
import SwiftUI

struct CachedIconImage<Placeholder: View>: View {
    let url: URL?
    var contentMode: SwiftUI.ContentMode = .fit
    @ViewBuilder let placeholder: () -> Placeholder

    var body: some View {
        KFImage(url)
            .placeholder(placeholder)
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }
}
