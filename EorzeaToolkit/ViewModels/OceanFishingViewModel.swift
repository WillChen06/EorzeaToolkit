import Foundation

@Observable
final class OceanFishingViewModel {
    private(set) var routes: [OceanFishingRoute] = []

    func loadRoutes() {
        do {
            let data: OceanFishingData = try LocalDataService.load("ocean_fishing")
            routes = data.routes
        } catch {
            print("Failed to load ocean fishing data: \(error)")
        }
    }
}
