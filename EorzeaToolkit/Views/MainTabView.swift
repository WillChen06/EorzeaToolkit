import SwiftUI

struct MainTabView: View {
    @State private var marketPriceSettings = MarketPriceSettings()

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .appThemedScreen(tint: AppTheme.crystal)
        .environment(marketPriceSettings)
    }
}

#Preview {
    MainTabView()
}
