import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TreasureMapListView()
            }
            .tabItem {
                Label("藏寶圖", systemImage: "map")
            }

            NavigationStack {
                RelicWeaponListView()
            }
            .tabItem {
                Label("發光武器", systemImage: "sparkles")
            }

            NavigationStack {
                OceanFishingView()
            }
            .tabItem {
                Label("海釣", systemImage: "fish")
            }

            NavigationStack {
                BattleJobListView()
            }
            .tabItem {
                Label("技能循環", systemImage: "bolt.circle")
            }

            NavigationStack {
                ProgressTrackerView()
            }
            .tabItem {
                Label("進度", systemImage: "checklist")
            }
        }
    }
}

#Preview {
    MainTabView()
}
