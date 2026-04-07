import Foundation

@Observable
final class RelicWeaponViewModel {
    private(set) var expansions: [Expansion] = []

    func loadWeapons() {
        do {
            let data: RelicWeaponData = try LocalDataService.load("relic_weapons")
            expansions = data.expansions
        } catch {
            print("Failed to load relic weapons: \(error)")
        }
    }
}
