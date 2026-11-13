import Testing
@testable import EorzeaToolkit

/// What the filter sheet offers, built from the loaded data.
struct ItemFilterOptionsTests {
    /// Groups follow `orderMajor`; within a group, `orderMinor` and then the name decide. The
    /// names are Latin letters, which sort the same in every locale.
    @Test func categoriesAreGroupedAndSorted() {
        let groups = UICategoryGroup.groups(from: [
            UICategory(id: 1, nameTw: "B", orderMinor: 1, orderMajor: 2),
            UICategory(id: 2, nameTw: "A", orderMinor: 2, orderMajor: 1),
            UICategory(id: 3, nameTw: "Z", orderMinor: 1, orderMajor: 1),
            UICategory(id: 4, nameTw: "Y", orderMinor: 1, orderMajor: 1)
        ])

        #expect(groups.map(\.orderMajor) == [1, 2])
        #expect(groups.map { $0.categories.map(\.id) } == [[4, 3, 2], [1]])
    }

    @Test func noCategoriesMeansNoGroups() {
        #expect(UICategoryGroup.groups(from: []).isEmpty)
    }

    /// Only jobs some category names are offered, in the list's own order, whatever order
    /// the data names them in.
    @Test func onlyJobsTheDataNamesAreOffered() {
        let options = ItemJobFilterOption.available(in: [
            1: ["BLM"],
            2: ["WHM", "BLM"],
            3: ["XYZ"]
        ])

        #expect(options.map(\.abbreviation) == ["WHM", "BLM"])
    }

    @Test func noJobsMeansNoOptions() {
        #expect(ItemJobFilterOption.available(in: [:]).isEmpty)
        #expect(ItemJobFilterOption.available(in: [1: []]).isEmpty)
    }
}
