import SwiftUI
import SwiftData

@main
struct EorzeaToolkitApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [RelicWeaponProgress.self, SkillRotationSlotRecord.self])
    }
}
