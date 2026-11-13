/// Kept apart from `ItemJobFilterOption.swift`, which the item query evaluation tool (macOS)
/// compiles without the app's localization.
extension ItemJobFilterOption {
    var displayName: String {
        L10n.ItemSearch.Filter.jobName(abbreviation)
    }
}
