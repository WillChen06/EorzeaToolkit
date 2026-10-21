import SwiftUI
import SwiftData

@main
struct EorzeaToolkitApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [RelicWeaponProgress.self, SkillRotationSlotRecord.self])
    }
}
