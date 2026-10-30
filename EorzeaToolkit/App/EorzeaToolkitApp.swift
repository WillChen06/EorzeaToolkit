import SwiftUI
import SwiftData

@main
struct EorzeaToolkitApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(PersistenceController.container)
    }
}
