import Foundation

@Observable
final class RelicWeaponViewModel {
    private(set) var weaponSeries: WeaponSeries?
    private(set) var loadError: String?

    private var progressByJob: [String: Set<Int>] = [:]
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadWeapons() {
        do {
            let data: RelicWeaponData = try LocalDataService.load("relic_weapons")
            weaponSeries = data.weaponSeries
            progressByJob = loadProgress(for: data.weaponSeries.id)
            loadError = nil
        } catch {
            weaponSeries = nil
            loadError = error.localizedDescription
        }
    }

    func isStageCompleted(_ stage: WeaponStage, for job: String) -> Bool {
        completedStages(for: job).contains(stage.stageIndex)
    }

    func completedStageCount(for job: String) -> Int {
        completedStages(for: job).count
    }

    func toggleStage(_ stage: WeaponStage, for job: String) {
        guard let seriesID = weaponSeries?.id else {
            return
        }

        var completedStages = progressByJob[job, default: []]

        if completedStages.contains(stage.stageIndex) {
            completedStages.remove(stage.stageIndex)
        } else {
            completedStages.insert(stage.stageIndex)
        }

        progressByJob[job] = completedStages
        saveProgress(for: seriesID)
    }

    private func completedStages(for job: String) -> Set<Int> {
        progressByJob[job, default: []]
    }

    private func loadProgress(for seriesID: String) -> [String: Set<Int>] {
        guard let data = userDefaults.data(forKey: progressStorageKey(for: seriesID)) else {
            return [:]
        }

        do {
            let decoded = try JSONDecoder().decode([String: [Int]].self, from: data)
            return decoded.mapValues(Set.init)
        } catch {
            return [:]
        }
    }

    private func saveProgress(for seriesID: String) {
        let encodedProgress = progressByJob.mapValues { stages in
            stages.sorted()
        }

        guard let data = try? JSONEncoder().encode(encodedProgress) else {
            return
        }

        userDefaults.set(data, forKey: progressStorageKey(for: seriesID))
    }

    private func progressStorageKey(for seriesID: String) -> String {
        "relicWeaponProgress.\(seriesID)"
    }
}
