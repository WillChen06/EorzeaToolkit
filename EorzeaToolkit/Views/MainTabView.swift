import SwiftUI

struct MainTabView: View {
    @State private var marketPriceSettings = MarketPriceSettings()
    @State private var selectedFeature: HomeFeature?

    var body: some View {
        Group {
            if let selectedFeature {
                selectedFeature.destination {
                    self.selectedFeature = nil
                }
            } else {
                NavigationStack {
                    HomeView { selectedFeature = $0 }
                }
            }
        }
        .appThemedScreen(tint: AppTheme.crystal)
        .environment(marketPriceSettings)
    }
}

#Preview {
    MainTabView()
}
