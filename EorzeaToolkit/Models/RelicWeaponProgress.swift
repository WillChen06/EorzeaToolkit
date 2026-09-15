import Foundation
import SwiftData

@Model
final class RelicWeaponProgress {
    var seriesID: String
    var job: String
    var completedStageIndices: [Int]

    init(seriesID: String, job: String, completedStageIndices: [Int] = []) {
        self.seriesID = seriesID
        self.job = job
        self.completedStageIndices = completedStageIndices
    }
}
