import Foundation

@Observable
final class TreasureMapViewModel {
    private(set) var maps: [TreasureMap] = []

    func loadMaps() {
        do {
            let data: TreasureMapData = try LocalDataService.load("treasure_maps")
            maps = data.maps
        } catch {
            print("Failed to load treasure maps: \(error)")
        }
    }
}
