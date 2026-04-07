import Foundation
import SwiftData

@Model
final class ProgressRecord {
    var targetID: String
    var targetType: String
    var targetName: String
    var currentStep: Int
    var totalSteps: Int
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        targetID: String,
        targetType: String,
        targetName: String,
        currentStep: Int = 0,
        totalSteps: Int,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.targetID = targetID
        self.targetType = targetType
        self.targetName = targetName
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
