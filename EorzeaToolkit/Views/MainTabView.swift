import SwiftUI

struct MainTabView: View {
    @State private var marketPriceSettings = MarketPriceSettings()

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environment(marketPriceSettings)
    }
}

#Preview {
    MainTabView()
}
