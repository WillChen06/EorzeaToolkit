import SwiftData
import XCTest
@testable import EorzeaToolkit

@MainActor
final class SkillRotationPersistenceTests: XCTestCase {
    func testAddingSkillPersistsAndAppearsInRotation() throws {
        let (_, context, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)

        viewModel.addSkill(action, to: job.id, level: .level50)

        let slot = try XCTUnwrap(viewModel.rotation(for: job.id, level: .level50).first)
        guard case .action(let storedAction) = slot.item else {
            return XCTFail("Expected an action slot")
        }
        XCTAssertEqual(storedAction, action)
        let record = try XCTUnwrap(try records(in: context).first)
        XCTAssertEqual(record.id, slot.id)
        XCTAssertEqual(record.jobID, job.id)
        XCTAssertEqual(record.level, SkillRotationLevel.level50.rawValue)
        XCTAssertEqual(record.position, 0)
        XCTAssertEqual(record.slotType, "action")
        XCTAssertEqual(record.actionID, action.id)
    }

    func testAddingTincturePersistsAndAppearsInRotation() throws {
        let (_, context, viewModel) = try makeSystemUnderTest()
        let job = try XCTUnwrap(viewModel.jobs.first)
        let tincture = try XCTUnwrap(viewModel.tinctures.first)

        viewModel.addTincture(tincture, to: job.id, level: .level60)

        let slot = try XCTUnwrap(viewModel.rotation(for: job.id, level: .level60).first)
        guard case .tincture(let storedTincture) = slot.item else {
            return XCTFail("Expected a tincture slot")
        }
        XCTAssertEqual(storedTincture, tincture)
        let record = try XCTUnwrap(try records(in: context).first)
        XCTAssertEqual(record.slotType, "tincture")
        XCTAssertEqual(record.tinctureID, tincture.id)
    }

    func testRemovingSlotDeletesPersistedRecord() throws {
        let (_, context, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)
        viewModel.addSkill(action, to: job.id, level: .level70)
        let slotID = try XCTUnwrap(viewModel.rotation(for: job.id, level: .level70).first?.id)

        viewModel.removeSlot(id: slotID, from: job.id, level: .level70)

        XCTAssertFalse(viewModel.rotation(for: job.id, level: .level70).contains { $0.id == slotID })
        XCTAssertFalse(try records(in: context).contains { $0.id == slotID })
    }

    func testMovingSlotPersistsNewOrderAcrossReload() throws {
        let (container, context, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)
        viewModel.addSkill(action, to: job.id, level: .level80)
        viewModel.addSkill(action, to: job.id, level: .level80)
        viewModel.addSkill(action, to: job.id, level: .level80)
        let original = viewModel.rotation(for: job.id, level: .level80)

        viewModel.moveSlot(in: job.id, level: .level80, fromID: original[2].id, toIndex: 0)

        let expectedIDs = [original[2].id, original[0].id, original[1].id]
        XCTAssertEqual(viewModel.rotation(for: job.id, level: .level80).map(\.id), expectedIDs)
        XCTAssertEqual(
            try records(in: context).sorted { $0.position < $1.position }.map(\.position),
            [0, 1, 2]
        )
        let reloaded = try reloadViewModel(using: container)
        XCTAssertEqual(reloaded.rotation(for: job.id, level: .level80).map(\.id), expectedIDs)
    }

    func testClearingRotationRemovesLevelFromSavedLevels() throws {
        let (_, context, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)
        viewModel.addSkill(action, to: job.id, level: .level90)

        viewModel.clearRotation(for: job.id, level: .level90)

        XCTAssertFalse(viewModel.savedLevels(for: job.id).contains(.level90))
        XCTAssertFalse(try records(in: context).contains {
            $0.jobID == job.id && $0.level == SkillRotationLevel.level90.rawValue
        })
    }

    func testClearingOneLevelDoesNotAffectAnotherLevelOfSameJob() throws {
        let (_, context, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)
        viewModel.addSkill(action, to: job.id, level: .level50)
        viewModel.addSkill(action, to: job.id, level: .level60)
        let level60 = viewModel.rotation(for: job.id, level: .level60)

        viewModel.clearRotation(for: job.id, level: .level50)

        XCTAssertEqual(viewModel.rotation(for: job.id, level: .level60), level60)
        XCTAssertTrue(try records(in: context).contains { $0.id == level60[0].id })
    }

    func testEditingOneJobDoesNotAffectAnotherJob() throws {
        let (_, context, viewModel) = try makeSystemUnderTest()
        let jobs = viewModel.jobs.filter { !$0.actions.isEmpty }
        let jobA = try XCTUnwrap(jobs.first)
        let jobB = try XCTUnwrap(jobs.dropFirst().first)
        let actionA = try XCTUnwrap(jobA.actions.first)
        let actionB = try XCTUnwrap(jobB.actions.first)
        viewModel.addSkill(actionB, to: jobB.id, level: .level100)
        let jobBRotation = viewModel.rotation(for: jobB.id, level: .level100)
        viewModel.addSkill(actionA, to: jobA.id, level: .level100)
        viewModel.addSkill(actionA, to: jobA.id, level: .level100)
        viewModel.addSkill(actionA, to: jobA.id, level: .level100)
        let jobASlots = viewModel.rotation(for: jobA.id, level: .level100)

        viewModel.moveSlot(in: jobA.id, level: .level100, fromID: jobASlots[2].id, toIndex: 0)
        viewModel.removeSlot(id: jobASlots[1].id, from: jobA.id, level: .level100)

        XCTAssertEqual(viewModel.rotation(for: jobB.id, level: .level100), jobBRotation)
        XCTAssertTrue(try records(in: context).contains { $0.id == jobBRotation[0].id })
    }

    func testReloadingRestoresFullRotationContent() throws {
        let (container, _, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)
        let tincture = try XCTUnwrap(viewModel.tinctures.first)
        viewModel.addSkill(action, to: job.id, level: .level100)
        viewModel.addTincture(tincture, to: job.id, level: .level100)
        let original = viewModel.rotation(for: job.id, level: .level100)
        viewModel.moveSlot(in: job.id, level: .level100, fromID: original[1].id, toIndex: 0)
        let expected = viewModel.rotation(for: job.id, level: .level100)

        let reloaded = try reloadViewModel(using: container)

        XCTAssertEqual(reloaded.rotation(for: job.id, level: .level100), expected)
    }

    func testRestoringSkipsRecordsReferencingMissingCatalogEntries() throws {
        let (container, context, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)
        viewModel.addSkill(action, to: job.id, level: .level50)
        let validSlot = try XCTUnwrap(viewModel.rotation(for: job.id, level: .level50).first)
        context.insert(SkillRotationSlotRecord(
            id: UUID(), jobID: job.id, level: 50, position: 1,
            slotType: "action", actionID: Int.max
        ))
        context.insert(SkillRotationSlotRecord(
            id: UUID(), jobID: job.id, level: 50, position: 2,
            slotType: "tincture", tinctureID: Int.max
        ))
        try context.save()

        let reloaded = try reloadViewModel(using: container)

        XCTAssertEqual(reloaded.rotation(for: job.id, level: .level50).map(\.id), [validSlot.id])
    }

    func testDuplicateSkillEntriesAreIndependentSlots() throws {
        let (_, context, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)
        viewModel.addSkill(action, to: job.id, level: .level60)
        viewModel.addSkill(action, to: job.id, level: .level60)
        let slots = viewModel.rotation(for: job.id, level: .level60)
        XCTAssertEqual(slots.count, 2)
        XCTAssertNotEqual(slots[0].id, slots[1].id)

        viewModel.removeSlot(id: slots[0].id, from: job.id, level: .level60)

        XCTAssertEqual(viewModel.rotation(for: job.id, level: .level60).map(\.id), [slots[1].id])
        XCTAssertEqual(try records(in: context).map(\.id), [slots[1].id])
    }

    func testAddingAfterRemovalRemainsAtTailAcrossReload() throws {
        let (container, _, viewModel) = try makeSystemUnderTest()
        let (job, action) = try firstJobAndAction(in: viewModel)
        viewModel.addSkill(action, to: job.id, level: .level70)
        viewModel.addSkill(action, to: job.id, level: .level70)
        viewModel.addSkill(action, to: job.id, level: .level70)
        let original = viewModel.rotation(for: job.id, level: .level70)
        viewModel.removeSlot(id: original[1].id, from: job.id, level: .level70)
        viewModel.addSkill(action, to: job.id, level: .level70)
        let expectedIDs = viewModel.rotation(for: job.id, level: .level70).map(\.id)

        let reloaded = try reloadViewModel(using: container)

        XCTAssertEqual(Array(expectedIDs.prefix(2)), [original[0].id, original[2].id])
        XCTAssertEqual(reloaded.rotation(for: job.id, level: .level70).map(\.id), expectedIDs)
    }

    private func makeSystemUnderTest() throws -> (ModelContainer, ModelContext, SkillRotationViewModel) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SkillRotationSlotRecord.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let viewModel = SkillRotationViewModel()
        viewModel.configure(modelContext: context)
        viewModel.load()
        XCTAssertNil(viewModel.loadError)
        return (container, context, viewModel)
    }

    private func reloadViewModel(using container: ModelContainer) throws -> SkillRotationViewModel {
        let viewModel = SkillRotationViewModel()
        viewModel.configure(modelContext: ModelContext(container))
        viewModel.load()
        XCTAssertNil(viewModel.loadError)
        return viewModel
    }

    private func firstJobAndAction(
        in viewModel: SkillRotationViewModel
    ) throws -> (BattleJob, BattleAction) {
        let job = try XCTUnwrap(viewModel.jobs.first { !$0.actions.isEmpty })
        return (job, try XCTUnwrap(job.actions.first))
    }

    private func records(in context: ModelContext) throws -> [SkillRotationSlotRecord] {
        try context.fetch(FetchDescriptor<SkillRotationSlotRecord>())
    }
}
