import Foundation
import SwiftData

@Observable
@MainActor
final class RelicWeaponViewModel {
    private(set) var weaponSeriesList: [WeaponSeries] = []
    private(set) var hasLoadedWeapons = false
    private(set) var loadError: String?

    private var progressByKey: [ProgressKey: Set<Int>] = [:]
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadWeapons() {
        do {
            let data: RelicWeaponData = try LocalDataService.load("relic_weapons")
            weaponSeriesList = data.weaponSeriesList
            loadProgress(for: data.weaponSeriesList)
            hasLoadedWeapons = true
            loadError = nil
        } catch {
            weaponSeriesList = []
            hasLoadedWeapons = true
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
        let key = ProgressKey(seriesID: seriesID, job: job)
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
        progressByKey[ProgressKey(seriesID: seriesID, job: job), default: []]
    }

    private func loadProgress(for seriesList: [WeaponSeries]) {
        progressByKey = [:]

        guard let modelContext,
              let storedProgress = try? modelContext.fetch(FetchDescriptor<RelicWeaponProgress>()) else {
            return
        }

        let validKeys = Set(seriesList.flatMap { series in
            series.availableJobs.map { ProgressKey(seriesID: series.id, job: $0) }
        })

        for progress in storedProgress {
            let key = ProgressKey(seriesID: progress.seriesID, job: progress.job)
            guard validKeys.contains(key) else {
                continue
            }

            progressByKey[key, default: []].formUnion(progress.completedStageIndices)
        }
    }

    private func saveProgress(_ completedStages: Set<Int>, for seriesID: String, job: String) {
        guard let modelContext else {
            return
        }

        let targetSeriesID = seriesID
        let targetJob = job
        let descriptor = FetchDescriptor<RelicWeaponProgress>(
            predicate: #Predicate { progress in
                progress.seriesID == targetSeriesID && progress.job == targetJob
            }
        )

        do {
            let matchingProgress = try modelContext.fetch(descriptor)
            let progress = matchingProgress.first ?? RelicWeaponProgress(seriesID: seriesID, job: job)

            if matchingProgress.isEmpty {
                modelContext.insert(progress)
            }

            progress.completedStageIndices = completedStages.sorted()

            for duplicate in matchingProgress.dropFirst() {
                modelContext.delete(duplicate)
            }

            try modelContext.save()
        } catch {
            modelContext.rollback()
            loadProgress(for: weaponSeriesList)
        }
    }
}

private struct ProgressKey: Hashable {
    let seriesID: String
    let job: String
}
