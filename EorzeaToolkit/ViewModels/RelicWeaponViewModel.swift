import Foundation

@Observable
final class RelicWeaponViewModel {
    private(set) var weaponSeriesList: [WeaponSeries] = []
    private(set) var loadError: String?

    private var progressByKey: [String: Set<Int>] = [:]
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadWeapons() {
        do {
            let data: RelicWeaponData = try LocalDataService.load("relic_weapons")
            weaponSeriesList = data.weaponSeriesList
            loadProgress(for: data.weaponSeriesList)
            loadError = nil
        } catch {
            weaponSeriesList = []
            loadError = error.localizedDescription
        }
    }

    func isStageCompleted(_ stage: WeaponStage, for seriesID: String, job: String) -> Bool {
        completedStages(for: seriesID, job: job).contains(stage.stageIndex)
    }

    func completedStageCount(for seriesID: String, job: String) -> Int {
        completedStages(for: seriesID, job: job).count
    }

    func toggleStage(_ stage: WeaponStage, for seriesID: String, job: String) {
        let key = progressStorageKey(for: seriesID, job: job)
        var completedStages = progressByKey[key, default: []]

        if completedStages.contains(stage.stageIndex) {
            completedStages.remove(stage.stageIndex)
        } else {
            completedStages.insert(stage.stageIndex)
        }

        progressByKey[key] = completedStages
        saveProgress(completedStages, for: seriesID, job: job)
    }

    private func completedStages(for seriesID: String, job: String) -> Set<Int> {
        progressByKey[progressStorageKey(for: seriesID, job: job), default: []]
    }

    private func loadProgress(for seriesList: [WeaponSeries]) {
        progressByKey = [:]

        for series in seriesList {
            for job in series.availableJobs {
                let key = progressStorageKey(for: series.id, job: job)

                guard let data = userDefaults.data(forKey: key),
                      let decoded = try? JSONDecoder().decode([Int].self, from: data) else {
                    continue
                }

                progressByKey[key] = Set(decoded)
            }
        }
    }

    private func saveProgress(_ completedStages: Set<Int>, for seriesID: String, job: String) {
        guard let data = try? JSONEncoder().encode(completedStages.sorted()) else {
            return
        }

        userDefaults.set(data, forKey: progressStorageKey(for: seriesID, job: job))
    }

    private func progressStorageKey(for seriesID: String, job: String) -> String {
        "relicWeaponProgress.\(seriesID).\(job)"
    }
}
