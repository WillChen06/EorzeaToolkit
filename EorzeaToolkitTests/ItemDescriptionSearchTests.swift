import XCTest
@testable import EorzeaToolkit

/// Description search in the item search: model status, applying a parsed sentence, recipe
/// lookups, messages and abandoned parses (prompts/item-description-search.md).
@MainActor
final class ItemDescriptionSearchTests: XCTestCase {
    private enum Fixture {
        static let shield = 10
        static let twoHandedConjury = 11
        static let mainHand = 1
        static let offHand = 2
        static let body = 4
        static let bodyNoHead = 15
        static let whiteMage = 1

        static let data = makeData(categoryName: "盾")

        /// The same items with the shield category renamed, standing in for a remote update.
        static let updatedData = makeData(categoryName: "大盾")

        static func makeData(categoryName: String) -> ItemDataResponse {
            ItemDataResponse(
                items: [
                    item(id: 1, name: "白鋼錠"),
                    item(id: 2, name: "奶油"),
                    item(id: 3, name: "奶油"),
                    item(id: 4, name: "EX無瑕白染劑"),
                    item(id: 5, name: "白魔長袍", job: whiteMage, equipSlot: body, equipLevel: 90)
                ],
                uiCategories: [
                    UICategory(id: shield, nameTw: categoryName, orderMinor: 1, orderMajor: 1),
                    UICategory(id: twoHandedConjury, nameTw: "雙手幻杖", orderMinor: 2, orderMajor: 1)
                ],
                classjobCategories: [ClassJobCategory(id: whiteMage, nameTw: "白魔道士", jobs: ["WHM"])],
                equipSlots: [
                    EquipSlot(id: mainHand, nameTw: "主手"),
                    EquipSlot(id: offHand, nameTw: "副手"),
                    EquipSlot(id: body, nameTw: "身體"),
                    EquipSlot(id: bodyNoHead, nameTw: "身體（無法裝備頭部）")
                ]
            )
        }

        static func item(id: Int, name: String, job: Int = 0, equipSlot: Int = 0, equipLevel: Int = 0) -> Item {
            Item(
                id: id,
                nameTw: name,
                iconId: 0,
                iconPath: "",
                ilvl: 1,
                rarity: 1,
                canBeHq: false,
                isUntradable: false,
                classjobCategoryId: job,
                equipSlot: equipSlot,
                equipLevel: equipLevel
            )
        }
    }

    private struct ParseFailure: Error {}

    private var model: FakeModel!
    private var memory: ItemDescriptionSearchMemory!

    override func setUp() async throws {
        model = FakeModel()
        memory = ItemDescriptionSearchMemory()
    }

    private func loadedViewModel(
        refreshedData: ItemDataResponse? = nil,
        availability: ItemDescriptionSearchAvailability = .available
    ) async -> ItemSearchViewModel {
        model.availability = availability
        let viewModel = ItemSearchViewModel(
            descriptionSearchEngine: model.engine,
            descriptionSearchMemory: memory,
            loadData: { Fixture.data },
            refreshData: { _ in refreshedData }
        )
        viewModel.loadItems()
        await viewModel.waitUntilLoaded()
        await viewModel.waitUntilDescriptionSearchIsReady()
        viewModel.refreshDescriptionSearchAvailability()
        return viewModel
    }

    /// A view model whose filter and search text are all changed from their defaults, so that
    /// applying a sentence shows what it replaces.
    private func viewModelWithEverythingSet() async -> ItemSearchViewModel {
        let viewModel = await loadedViewModel()
        viewModel.updateSearchQuery("舊的文字")
        viewModel.toggleUICategory(Fixture.twoHandedConjury)
        viewModel.toggleEquipSlot(Fixture.offHand)
        viewModel.toggleJob("BLM")
        viewModel.updateMinimumEquipLevel(50)
        viewModel.updateMaximumItemLevel(300)
        viewModel.toggleRarity(1)
        viewModel.updateHQState(.only)
        viewModel.updateTradableState(.exclude)
        await viewModel.waitUntilSearchFinishes()
        return viewModel
    }

    /// Opens the screen, searches with `sentence`, waits for the parse, and, when the screen
    /// closed, lets it finish closing as the view reports.
    private func search(_ sentence: String, in viewModel: ItemSearchViewModel) async {
        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = sentence
        let parse = viewModel.submitDescription()
        XCTAssertNotNil(parse, "the search did not start")
        await parse?.value
        if !viewModel.isShowingDescriptionSearch {
            await viewModel.descriptionSearchDidClose()?.value
        }
        await viewModel.waitUntilSearchFinishes()
    }

    // MARK: - Model status (AC-7)

    func testTheButtonFollowsTheModelStatus() async {
        for availability in ItemDescriptionSearchAvailability.allCases {
            let viewModel = await loadedViewModel(availability: availability)

            XCTAssertEqual(viewModel.showsDescriptionSearchButton, availability.showsButton, "\(availability)")
        }
    }

    /// Apple Intelligence turned off and the model not ready open the screen to explain; only
    /// an available model searches.
    func testOnlyAnAvailableModelSearches() async {
        for availability in ItemDescriptionSearchAvailability.allCases where availability.showsButton {
            let viewModel = await loadedViewModel(availability: availability)
            model.answers["白鋼錠怎麼做"] = .success(ItemQuery(usage: .recipe, keyword: "白鋼錠"))

            viewModel.openDescriptionSearch()
            viewModel.descriptionSentence = "白鋼錠怎麼做"

            XCTAssertTrue(viewModel.isShowingDescriptionSearch, "\(availability)")
            XCTAssertEqual(viewModel.descriptionSearchAvailability, availability)
            XCTAssertEqual(viewModel.canSubmitDescription, availability == .available, "\(availability)")
            XCTAssertEqual(viewModel.submitDescription() != nil, availability == .available, "\(availability)")
        }
    }

    func testABlankSentenceCannotSearch() async {
        let viewModel = await loadedViewModel()
        viewModel.openDescriptionSearch()

        viewModel.descriptionSentence = "  "

        XCTAssertFalse(viewModel.canSubmitDescription)
        XCTAssertNil(viewModel.submitDescription())
    }

    /// The status is checked again when the screen opens. If it turned into one that hides the
    /// button, the screen still opens and explains, and the button goes once it closes.
    func testAStatusThatTurnsUnavailableKeepsTheOpenScreenButCannotSearch() async {
        let viewModel = await loadedViewModel(availability: .modelNotReady)
        XCTAssertTrue(viewModel.showsDescriptionSearchButton)

        model.availability = .unavailable
        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "白鋼錠怎麼做"

        XCTAssertTrue(viewModel.isShowingDescriptionSearch)
        XCTAssertEqual(viewModel.descriptionSearchAvailability, .unavailable)
        XCTAssertFalse(viewModel.canSubmitDescription)
        XCTAssertTrue(viewModel.showsDescriptionSearchButton, "the screen hangs from the button")

        viewModel.closeDescriptionSearch()

        XCTAssertFalse(viewModel.showsDescriptionSearchButton)
    }

    func testAStatusThatBecomesAvailableSearchesOnceTheScreenOpens() async {
        let viewModel = await loadedViewModel(availability: .modelNotReady)

        model.availability = .available
        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "白鋼錠怎麼做"

        XCTAssertTrue(viewModel.canSubmitDescription)
    }

    func testTheButtonWaitsForTheItems() async {
        let viewModel = ItemSearchViewModel(
            descriptionSearchEngine: model.engine,
            descriptionSearchMemory: memory,
            loadData: { Fixture.data },
            refreshData: { _ in nil }
        )
        XCTAssertFalse(viewModel.canOpenDescriptionSearch)

        viewModel.loadItems()
        await viewModel.waitUntilLoaded()
        await viewModel.waitUntilDescriptionSearchIsReady()

        XCTAssertTrue(viewModel.canOpenDescriptionSearch)
    }

    /// Before iOS 26 there is no button, and the vocabulary is never built.
    func testWithoutDescriptionSearchThereIsNoButton() async {
        let viewModel = ItemSearchViewModel(loadData: { Fixture.data }, refreshData: { _ in nil })
        viewModel.loadItems()
        await viewModel.waitUntilLoaded()
        await viewModel.waitUntilDescriptionSearchIsReady()
        viewModel.refreshDescriptionSearchAvailability()

        XCTAssertFalse(viewModel.showsDescriptionSearchButton)
        XCTAssertFalse(viewModel.canOpenDescriptionSearch)
        viewModel.openDescriptionSearch()
        XCTAssertFalse(viewModel.isShowingDescriptionSearch)
    }

    /// AC-23 asks the diff for prewarming; this pins down when it happens.
    func testOpeningPrewarmsOnlyAnAvailableModel() async {
        let available = await loadedViewModel(availability: .available)
        available.openDescriptionSearch()
        XCTAssertEqual(model.prewarmCount, 1)

        let notReady = await loadedViewModel(availability: .modelNotReady)
        notReady.openDescriptionSearch()
        XCTAssertEqual(model.prewarmCount, 1)
    }

    // MARK: - Applying (AC-10, AC-11)

    func testEachFieldReachesTheFilterAndTheSearchText() async {
        let viewModel = await viewModelWithEverythingSet()
        model.answers["句子"] = .success(ItemQuery(
            usage: .search,
            keyword: "長袍",
            categoryIds: [Fixture.shield],
            equipSlotIds: [Fixture.body, Fixture.bodyNoHead],
            jobs: ["WHM", "SCH"],
            equipLevelRange: 80...100,
            itemLevelRange: 690...795,
            rarities: [4],
            hq: false,
            tradable: true
        ))

        await search("句子", in: viewModel)

        var expected = ItemFilter()
        expected.selectedUICategoryIds = [Fixture.shield]
        expected.selectedEquipSlots = [Fixture.body, Fixture.bodyNoHead]
        expected.selectedJobAbbrs = ["WHM", "SCH"]
        expected.equipLevelRange = 80...100
        expected.ilvlRange = 690...795
        expected.selectedRarities = [4]
        expected.hqState = .exclude
        expected.tradableState = .only
        XCTAssertEqual(viewModel.filter, expected)
        XCTAssertEqual(viewModel.query, "長袍")
        XCTAssertFalse(viewModel.isShowingDescriptionSearch)
        XCTAssertNil(viewModel.descriptionSearchMessage)
    }

    /// Changing the filter and the search text while the screen animates away made it stutter,
    /// so the result waits until the screen has closed.
    func testTheResultIsAppliedOnlyOnceTheScreenHasClosed() async {
        let viewModel = await viewModelWithEverythingSet()
        let before = (viewModel.filter, viewModel.query)
        model.answers["白魔"] = .success(ItemQuery(usage: .search, jobs: ["WHM"]))
        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "白魔"

        await viewModel.submitDescription()?.value

        XCTAssertFalse(viewModel.isShowingDescriptionSearch)
        XCTAssertEqual(viewModel.filter, before.0)
        XCTAssertEqual(viewModel.query, before.1)

        // Dismissing reports closing too; the waiting result must survive it.
        viewModel.closeDescriptionSearch()
        viewModel.descriptionSearchDidClose()

        XCTAssertEqual(viewModel.filter.selectedJobAbbrs, ["WHM"])
        XCTAssertEqual(viewModel.query, "")

        viewModel.toggleJob("BLM")
        viewModel.descriptionSearchDidClose()
        XCTAssertEqual(viewModel.filter.selectedJobAbbrs, ["WHM", "BLM"], "applied only once")
    }

    /// Had the view never reported the screen closing, the waiting result must not surface
    /// when the screen next closes.
    func testReopeningDropsAResultThatWasNeverApplied() async {
        let viewModel = await viewModelWithEverythingSet()
        let before = (viewModel.filter, viewModel.query)
        model.answers["白魔"] = .success(ItemQuery(usage: .search, jobs: ["WHM"]))
        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "白魔"
        await viewModel.submitDescription()?.value

        viewModel.openDescriptionSearch()
        viewModel.closeDescriptionSearch()
        viewModel.descriptionSearchDidClose()

        XCTAssertEqual(viewModel.filter, before.0)
        XCTAssertEqual(viewModel.query, before.1)
    }

    /// A screen closed without a result, by 取消 or after a message, applies nothing.
    func testClosingWithoutAResultAppliesNothing() async {
        let viewModel = await viewModelWithEverythingSet()
        let before = (viewModel.filter, viewModel.query)
        model.answers["幫我找"] = .success(ItemQuery(usage: .search))
        await search("幫我找", in: viewModel)

        viewModel.closeDescriptionSearch()
        viewModel.descriptionSearchDidClose()

        XCTAssertEqual(viewModel.filter, before.0)
        XCTAssertEqual(viewModel.query, before.1)
    }

    func testTheOtherFlagValuesReachTheFilter() async {
        let viewModel = await loadedViewModel()
        model.answers["句子"] = .success(ItemQuery(usage: .search, equipLevelRange: 1...70, hq: true, tradable: false))

        await search("句子", in: viewModel)

        XCTAssertEqual(viewModel.filter.equipLevelRange, 1...70)
        XCTAssertEqual(viewModel.filter.hqState, .only)
        XCTAssertEqual(viewModel.filter.tradableState, .exclude)
    }

    /// Nothing is merged: every field the sentence did not mention goes back to its default,
    /// and no keyword clears the search text.
    func testApplyingReplacesTheWholeFilterAndSearchText() async {
        let viewModel = await viewModelWithEverythingSet()
        model.answers["白魔"] = .success(ItemQuery(usage: .search, jobs: ["WHM"]))

        await search("白魔", in: viewModel)

        var expected = ItemFilter()
        expected.selectedJobAbbrs = ["WHM"]
        XCTAssertEqual(viewModel.filter, expected)
        XCTAssertEqual(viewModel.query, "")
    }

    func testTheAppliedSearchRuns() async {
        let viewModel = await loadedViewModel()
        model.answers["白魔"] = .success(ItemQuery(usage: .search, jobs: ["WHM"]))

        await search("白魔", in: viewModel)

        XCTAssertEqual(viewModel.results.map(\.id), [5])
    }

    // MARK: - Recipe lookups (AC-12)

    /// An item named exactly the keyword opens, whether or not it has a recipe; the search text
    /// becomes the keyword and the filter goes back to its defaults.
    func testARecipeLookupOpensTheOnlyItemWithThatName() async {
        let viewModel = await viewModelWithEverythingSet()
        model.answers["白鋼錠怎麼做"] = .success(ItemQuery(usage: .recipe, keyword: "白鋼錠"))

        await search("白鋼錠怎麼做", in: viewModel)

        XCTAssertEqual(viewModel.itemIDToOpen, 1)
        XCTAssertEqual(viewModel.results.map(\.id), [1], "listed before it opens")
        XCTAssertEqual(viewModel.query, "白鋼錠")
        XCTAssertEqual(viewModel.filter, ItemFilter())
        XCTAssertFalse(viewModel.isShowingDescriptionSearch)

        viewModel.didOpenItem()
        XCTAssertNil(viewModel.itemIDToOpen)
    }

    func testARecipeLookupComparesNamesAsTheNameSearchDoes() async {
        let viewModel = await loadedViewModel()
        model.answers["染劑"] = .success(ItemQuery(usage: .recipe, keyword: "ex無瑕白染劑"))

        await search("染劑", in: viewModel)

        XCTAssertEqual(viewModel.itemIDToOpen, 4)
    }

    func testARecipeLookupWithSeveralNamesakesSearchesByName() async {
        let viewModel = await viewModelWithEverythingSet()
        model.answers["奶油怎麼做"] = .success(ItemQuery(usage: .recipe, keyword: "奶油"))

        await search("奶油怎麼做", in: viewModel)

        XCTAssertNil(viewModel.itemIDToOpen)
        XCTAssertEqual(viewModel.query, "奶油")
        XCTAssertEqual(viewModel.filter, ItemFilter())
        XCTAssertEqual(viewModel.results.map(\.id).sorted(), [2, 3])
    }

    func testARecipeLookupWithNoNamesakeSearchesByName() async {
        let viewModel = await viewModelWithEverythingSet()
        model.answers["白鋼怎麼做"] = .success(ItemQuery(usage: .recipe, keyword: "白鋼"))

        await search("白鋼怎麼做", in: viewModel)

        XCTAssertNil(viewModel.itemIDToOpen, "白鋼錠 only contains the keyword")
        XCTAssertEqual(viewModel.query, "白鋼")
        XCTAssertEqual(viewModel.filter, ItemFilter())
    }

    func testTheOnlyItemWithANameIsFoundWhateverItsCase() {
        let items = Fixture.data.items

        XCTAssertEqual(ItemSearchViewModel.onlyItemID(named: "白鋼錠", in: items), 1)
        XCTAssertEqual(ItemSearchViewModel.onlyItemID(named: "ex無瑕白染劑", in: items), 4)
        XCTAssertNil(ItemSearchViewModel.onlyItemID(named: "奶油", in: items), "two items")
        XCTAssertNil(ItemSearchViewModel.onlyItemID(named: "白鋼", in: items), "only part of a name")
    }

    // MARK: - Messages (AC-13, AC-14)

    /// Nothing is applied, the screen stays open with the sentence, and the message says why.
    private func assertNotApplied(
        _ viewModel: ItemSearchViewModel,
        message: ItemDescriptionSearchMessage,
        sentence: String,
        from before: (filter: ItemFilter, query: String),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(viewModel.descriptionSearchMessage, message, file: file, line: line)
        XCTAssertEqual(viewModel.filter, before.filter, file: file, line: line)
        XCTAssertEqual(viewModel.query, before.query, file: file, line: line)
        XCTAssertNil(viewModel.itemIDToOpen, file: file, line: line)
        XCTAssertTrue(viewModel.isShowingDescriptionSearch, file: file, line: line)
        XCTAssertFalse(viewModel.isParsingDescription, file: file, line: line)
        XCTAssertEqual(viewModel.descriptionSentence, sentence, file: file, line: line)
    }

    func testSentencesThatAreNoItemQueryApplyNothing() async {
        let cases: [(sentence: String, query: ItemQuery, message: ItemDescriptionSearchMessage)] = [
            ("吃了會加直擊的料理", ItemQuery(usage: .unsupported, keyword: "料理"), .notAnItemQuery),
            ("90級的怎麼做", ItemQuery(usage: .recipe, equipLevelRange: 90...90), .notAnItemQuery),
            ("幫我找", ItemQuery(usage: .search), .nothingFound)
        ]

        for (sentence, query, message) in cases {
            let viewModel = await viewModelWithEverythingSet()
            let before = (viewModel.filter, viewModel.query)
            model.answers[sentence] = .success(query)

            await search(sentence, in: viewModel)

            assertNotApplied(viewModel, message: message, sentence: sentence, from: before)
        }
    }

    /// A single condition, even a no, is something to search for.
    func testASingleConditionIsEnoughToApply() async {
        let queries = [
            ItemQuery(usage: .search, hq: false),
            ItemQuery(usage: .search, tradable: false),
            ItemQuery(usage: .search, rarities: [4]),
            ItemQuery(usage: .search, itemLevelRange: 600...795),
            ItemQuery(usage: .search, keyword: "長袍")
        ]

        for query in queries {
            let viewModel = await loadedViewModel()
            model.answers["句子"] = .success(query)

            await search("句子", in: viewModel)

            XCTAssertNil(viewModel.descriptionSearchMessage, "\(query)")
            XCTAssertFalse(viewModel.isShowingDescriptionSearch, "\(query)")
        }
    }

    /// The guardrails, an unreadable answer and any other error all end the same way.
    func testAParseThatFailsAppliesNothing() async {
        let viewModel = await viewModelWithEverythingSet()
        let before = (viewModel.filter, viewModel.query)
        model.answers["句子"] = .failure(ParseFailure())

        await search("句子", in: viewModel)

        assertNotApplied(viewModel, message: .failed, sentence: "句子", from: before)
    }

    func testSearchingAgainClearsTheMessage() async {
        let viewModel = await loadedViewModel()
        model.answers["句子"] = .failure(ParseFailure())
        await search("句子", in: viewModel)
        model.holds("句子")

        let parse = viewModel.submitDescription()
        await model.waitUntilParsing("句子")

        XCTAssertNil(viewModel.descriptionSearchMessage)
        model.finish("句子", with: .failure(ParseFailure()))
        await parse?.value
    }

    // MARK: - Parsing in progress and abandoned parses (AC-15, AC-19)

    func testWhileParsingTheSentenceCannotBeSearchedAgain() async {
        let viewModel = await loadedViewModel()
        model.holds("句子")
        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "句子"

        let parse = viewModel.submitDescription()
        await model.waitUntilParsing("句子")

        XCTAssertTrue(viewModel.isParsingDescription)
        XCTAssertFalse(viewModel.canSubmitDescription)
        XCTAssertNil(viewModel.submitDescription())

        model.finish("句子", with: .success(ItemQuery(usage: .search, jobs: ["WHM"])))
        await parse?.value
        XCTAssertFalse(viewModel.isParsingDescription)
    }

    /// The fake model ignores cancellation, so only the abandoned parse's own check keeps its
    /// result out.
    func testAResultThatArrivesAfterClosingIsNotApplied() async {
        let viewModel = await viewModelWithEverythingSet()
        let before = (viewModel.filter, viewModel.query)
        model.holds("句子")
        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "句子"
        let parse = viewModel.submitDescription()
        await model.waitUntilParsing("句子")

        viewModel.closeDescriptionSearch()
        model.finish("句子", with: .success(ItemQuery(usage: .search, jobs: ["WHM"])))
        await parse?.value
        await viewModel.waitUntilSearchFinishes()

        XCTAssertEqual(viewModel.filter, before.0)
        XCTAssertEqual(viewModel.query, before.1)
        XCTAssertNil(viewModel.descriptionSearchMessage)
        XCTAssertFalse(viewModel.isParsingDescription)
        XCTAssertFalse(viewModel.isShowingDescriptionSearch)
    }

    func testAnAbandonedFailureShowsNoMessage() async {
        let viewModel = await loadedViewModel()
        model.holds("句子")
        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "句子"
        let parse = viewModel.submitDescription()
        await model.waitUntilParsing("句子")

        viewModel.closeDescriptionSearch()
        viewModel.openDescriptionSearch()
        model.finish("句子", with: .failure(ParseFailure()))
        await parse?.value

        XCTAssertNil(viewModel.descriptionSearchMessage)
    }

    /// Only the latest parse applies, whichever answer comes back first.
    func testAnAbandonedParseDoesNotOverrideTheNextOne() async {
        let viewModel = await loadedViewModel()
        model.holds("白魔")
        model.holds("黑魔")

        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "白魔"
        let first = viewModel.submitDescription()
        await model.waitUntilParsing("白魔")
        viewModel.closeDescriptionSearch()

        viewModel.openDescriptionSearch()
        viewModel.descriptionSentence = "黑魔"
        let second = viewModel.submitDescription()
        await model.waitUntilParsing("黑魔")

        model.finish("黑魔", with: .success(ItemQuery(usage: .search, jobs: ["BLM"])))
        await second?.value
        model.finish("白魔", with: .success(ItemQuery(usage: .search, jobs: ["WHM"])))
        await first?.value
        viewModel.descriptionSearchDidClose()

        XCTAssertEqual(viewModel.filter.selectedJobAbbrs, ["BLM"])
    }

    // MARK: - The last sentence (AC-21)

    func testReopeningShowsTheLastSubmittedSentence() async {
        let viewModel = await loadedViewModel()
        model.answers["白魔"] = .success(ItemQuery(usage: .search, jobs: ["WHM"]))
        await search("白魔", in: viewModel)

        viewModel.openDescriptionSearch()
        XCTAssertEqual(viewModel.descriptionSentence, "白魔")

        viewModel.descriptionSentence = "只打字沒送出"
        viewModel.closeDescriptionSearch()
        viewModel.openDescriptionSearch()
        XCTAssertEqual(viewModel.descriptionSentence, "白魔", "a sentence only typed is not kept")
    }

    /// A sentence counts once searched with, even when it failed or was abandoned.
    func testFailedAndAbandonedSentencesCount() async {
        let viewModel = await loadedViewModel()
        model.answers["失敗的"] = .failure(ParseFailure())
        await search("失敗的", in: viewModel)
        viewModel.descriptionSentence = "失敗的，改過"
        viewModel.closeDescriptionSearch()

        viewModel.openDescriptionSearch()
        XCTAssertEqual(viewModel.descriptionSentence, "失敗的")

        model.holds("取消的")
        viewModel.descriptionSentence = "取消的"
        let parse = viewModel.submitDescription()
        await model.waitUntilParsing("取消的")
        viewModel.closeDescriptionSearch()
        model.finish("取消的", with: .failure(ParseFailure()))
        await parse?.value

        viewModel.openDescriptionSearch()
        XCTAssertEqual(viewModel.descriptionSentence, "取消的")
    }

    /// The item search screen is rebuilt each time it opens; the sentence outlives it.
    func testTheLastSentenceOutlivesTheItemSearchScreen() async {
        let first = await loadedViewModel()
        model.answers["白魔"] = .success(ItemQuery(usage: .search, jobs: ["WHM"]))
        await search("白魔", in: first)

        let second = await loadedViewModel()
        second.openDescriptionSearch()

        XCTAssertEqual(second.descriptionSentence, "白魔")
    }

    func testTheFirstOpeningIsEmpty() async {
        let viewModel = await loadedViewModel()

        viewModel.openDescriptionSearch()

        XCTAssertEqual(viewModel.descriptionSentence, "")
    }

    // MARK: - The same data as the search (「套用」)

    func testTheParserReadsTheSameDataAsTheSearch() async {
        let viewModel = await loadedViewModel()
        model.answers["句子"] = .success(ItemQuery(usage: .search, jobs: ["WHM"]))

        await search("句子", in: viewModel)

        XCTAssertEqual(model.categoryNamesOfLastParse, ["盾", "雙手幻杖"])
    }

    func testTheParserIsRebuiltFromARemoteUpdate() async {
        let viewModel = await loadedViewModel(refreshedData: Fixture.updatedData)
        model.answers["句子"] = .success(ItemQuery(usage: .search, jobs: ["WHM"]))

        await search("句子", in: viewModel)

        XCTAssertEqual(model.categoryNamesOfLastParse, ["大盾", "雙手幻杖"])
    }
}

/// A model whose answers the test sets, sentence by sentence. A held sentence stays in
/// progress, ignoring cancellation, until the test finishes it.
private final class FakeModel: @unchecked Sendable {
    private let lock = NSLock()
    private var availabilityValue: ItemDescriptionSearchAvailability = .available
    private var answersValue: [String: Result<ItemQuery, Error>] = [:]
    private var heldSentences: Set<String> = []
    private var pending: [String: CheckedContinuation<ItemQuery, Error>] = [:]
    private var arrivals: [String: CheckedContinuation<Void, Never>] = [:]
    private var prewarms = 0
    private var lastParseCategoryNames: Set<String> = []

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    var availability: ItemDescriptionSearchAvailability {
        get { locked { availabilityValue } }
        set { locked { availabilityValue = newValue } }
    }

    var answers: [String: Result<ItemQuery, Error>] {
        get { locked { answersValue } }
        set { locked { answersValue = newValue } }
    }

    var prewarmCount: Int {
        locked { prewarms }
    }

    /// The categories in the vocabulary of the parser that parsed last.
    var categoryNamesOfLastParse: Set<String> {
        locked { lastParseCategoryNames }
    }

    var engine: ItemDescriptionSearchEngine {
        ItemDescriptionSearchEngine(
            isSupported: true,
            availability: { self.availability },
            makeParser: { vocabulary in
                let categoryNames = Set(vocabulary.categories.map(\.name))
                return ItemDescriptionParser(
                    parse: { sentence in
                        self.locked { self.lastParseCategoryNames = categoryNames }
                        return try await self.parse(sentence)
                    },
                    prewarm: { self.locked { self.prewarms += 1 } }
                )
            }
        )
    }

    func holds(_ sentence: String) {
        locked { _ = heldSentences.insert(sentence) }
    }

    func waitUntilParsing(_ sentence: String) async {
        await withCheckedContinuation { (arrival: CheckedContinuation<Void, Never>) in
            let isParsing = locked {
                if pending[sentence] != nil {
                    return true
                }
                arrivals[sentence] = arrival
                return false
            }
            if isParsing {
                arrival.resume()
            }
        }
    }

    func finish(_ sentence: String, with result: Result<ItemQuery, Error>) {
        let continuation = locked {
            heldSentences.remove(sentence)
            return pending.removeValue(forKey: sentence)
        }
        continuation?.resume(with: result)
    }

    private func parse(_ sentence: String) async throws -> ItemQuery {
        let isHeld = locked { heldSentences.contains(sentence) }
        guard isHeld else {
            guard let answer = answers[sentence] else {
                throw CancellationError()
            }
            return try answer.get()
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ItemQuery, Error>) in
            let arrival = locked {
                pending[sentence] = continuation
                return arrivals.removeValue(forKey: sentence)
            }
            arrival?.resume()
        }
    }
}
