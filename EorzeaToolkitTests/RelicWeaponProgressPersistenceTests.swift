import SwiftData
import XCTest
@testable import EorzeaToolkit

@MainActor
final class RelicWeaponProgressPersistenceTests: XCTestCase {
    func testTogglingStageMarksItCompleted() throws {
        let (viewModel, context) = try makeSystemUnderTest()

        viewModel.toggleStage(stage(index: 1), for: "series-a", job: "PLD")

        XCTAssertTrue(viewModel.isStageCompleted(stage(index: 1), for: "series-a", job: "PLD"))
        let storedProgress = try XCTUnwrap(try context.fetch(FetchDescriptor<RelicWeaponProgress>()).first)
        XCTAssertEqual(storedProgress.completedStageIndices, [1])
    }

    func testTogglingCompletedStageTwiceRevertsToIncomplete() throws {
        let (viewModel, context) = try makeSystemUnderTest()
        let targetStage = stage(index: 1)

        viewModel.toggleStage(targetStage, for: "series-a", job: "PLD")
        viewModel.toggleStage(targetStage, for: "series-a", job: "PLD")

        XCTAssertFalse(viewModel.isStageCompleted(targetStage, for: "series-a", job: "PLD"))
        XCTAssertEqual(viewModel.completedStageCount(for: "series-a", job: "PLD"), 0)
        let storedProgress = try XCTUnwrap(try context.fetch(FetchDescriptor<RelicWeaponProgress>()).first)
        XCTAssertTrue(storedProgress.completedStageIndices.isEmpty)
    }

    func testProgressIsIsolatedPerSeriesAndJobCombination() throws {
        let (viewModel, context) = try makeSystemUnderTest()
        let targetStage = stage(index: 2)

        viewModel.toggleStage(targetStage, for: "series-a", job: "PLD")

        XCTAssertTrue(viewModel.isStageCompleted(targetStage, for: "series-a", job: "PLD"))
        XCTAssertFalse(viewModel.isStageCompleted(targetStage, for: "series-b", job: "PLD"))
        XCTAssertFalse(viewModel.isStageCompleted(targetStage, for: "series-a", job: "WAR"))

        let storedProgress = try context.fetch(FetchDescriptor<RelicWeaponProgress>())
        XCTAssertEqual(storedProgress.count, 1)
        XCTAssertEqual(storedProgress.first?.seriesID, "series-a")
        XCTAssertEqual(storedProgress.first?.job, "PLD")
    }

    func testUnsetProgressDefaultsToZeroCompletedStages() throws {
        let (viewModel, context) = try makeSystemUnderTest()

        XCTAssertFalse(viewModel.isStageCompleted(stage(index: 1), for: "series-a", job: "PLD"))
        XCTAssertEqual(viewModel.completedStageCount(for: "series-a", job: "PLD"), 0)
        XCTAssertTrue(try context.fetch(FetchDescriptor<RelicWeaponProgress>()).isEmpty)
    }

    func testCompletedStageCountReflectsMultipleCompletedStages() throws {
        let (viewModel, context) = try makeSystemUnderTest()

        viewModel.toggleStage(stage(index: 1), for: "series-a", job: "PLD")
        viewModel.toggleStage(stage(index: 2), for: "series-a", job: "PLD")
        viewModel.toggleStage(stage(index: 3), for: "series-a", job: "PLD")

        XCTAssertEqual(viewModel.completedStageCount(for: "series-a", job: "PLD"), 3)
        let storedProgress = try XCTUnwrap(try context.fetch(FetchDescriptor<RelicWeaponProgress>()).first)
        XCTAssertEqual(storedProgress.completedStageIndices, [1, 2, 3])
    }

    private func makeSystemUnderTest() throws -> (RelicWeaponViewModel, ModelContext) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RelicWeaponProgress.self, configurations: configuration)
        let context = ModelContext(container)
        let viewModel = RelicWeaponViewModel()
        viewModel.configure(modelContext: context)
        return (viewModel, context)
    }

    private func stage(index: Int) -> WeaponStage {
        WeaponStage(
            stageIndex: index,
            nameTw: "Stage \(index)",
            taskDescriptionTw: "",
            ilvl: nil,
            materials: []
        )
    }
}
