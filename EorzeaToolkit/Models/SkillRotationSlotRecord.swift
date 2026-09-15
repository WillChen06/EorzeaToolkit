import Foundation
import SwiftData

@Model
final class SkillRotationSlotRecord {
    var id: UUID
    var jobID: Int
    var level: Int
    var position: Int
    var slotType: String
    var actionID: Int?
    var tinctureID: Int?

    init(
        id: UUID,
        jobID: Int,
        level: Int,
        position: Int,
        slotType: String,
        actionID: Int? = nil,
        tinctureID: Int? = nil
    ) {
        self.id = id
        self.jobID = jobID
        self.level = level
        self.position = position
        self.slotType = slotType
        self.actionID = actionID
        self.tinctureID = tinctureID
    }
}
