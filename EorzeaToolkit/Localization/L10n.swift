import SwiftUI

enum L10n {
    enum Common {
        static let clear: LocalizedStringKey = "common.clear"
        static let done: LocalizedStringKey = "common.done"
        static let retry: LocalizedStringKey = "common.retry"
        static let selected: LocalizedStringKey = "common.selected"
        static let notSelected: LocalizedStringKey = "common.notSelected"

        static var noDataText: String {
            String(localized: "common.noData")
        }
    }

    enum ItemSearch {
        static let title: LocalizedStringKey = "itemSearch.title"
        static let loadingItems: LocalizedStringKey = "itemSearch.loadingItems"
        static let loadFailedTitle: LocalizedStringKey = "itemSearch.loadFailedTitle"
        static let searchPrompt: LocalizedStringKey = "itemSearch.searchPrompt"
        static let filterAction: LocalizedStringKey = "itemSearch.filter.action"
        static let filterAccessibility: LocalizedStringKey = "itemSearch.filter.accessibility"
        static let adjustFilter: LocalizedStringKey = "itemSearch.filter.adjust"
        static let emptySearchTitle: LocalizedStringKey = "itemSearch.search.emptyTitle"
        static let emptySearchDescription: LocalizedStringKey = "itemSearch.search.emptyDescription"
        static let searching: LocalizedStringKey = "itemSearch.search.loading"
        static let noResultsTitle: LocalizedStringKey = "itemSearch.search.noResultsTitle"
        static let noResultsDescription: LocalizedStringKey = "itemSearch.search.noResultsDescription"
        static let loadMore: LocalizedStringKey = "itemSearch.results.loadMore"

        static func resultsStatus(visibleCount: Int, totalCount: Int, hiddenCount: Int) -> LocalizedStringKey {
            "itemSearch.results.status \(visibleCount) \(totalCount) \(hiddenCount)"
        }

        static func itemLevel(_ itemLevel: Int) -> LocalizedStringKey {
            "itemSearch.row.itemLevel \(itemLevel)"
        }

        enum Filter {
            static let title: LocalizedStringKey = "itemSearch.filter.title"
            static let type: LocalizedStringKey = "itemSearch.filter.type"
            static let general: LocalizedStringKey = "itemSearch.filter.page.general"
            static let advanced: LocalizedStringKey = "itemSearch.filter.page.advanced"
            static let itemLevel: LocalizedStringKey = "itemSearch.filter.itemLevel.section"
            static let itemLevelMinimum: LocalizedStringKey = "itemSearch.filter.itemLevel.minimum"
            static let itemLevelMaximum: LocalizedStringKey = "itemSearch.filter.itemLevel.maximum"
            static let rarity: LocalizedStringKey = "itemSearch.filter.rarity.section"
            static let hq: LocalizedStringKey = "itemSearch.filter.hq.section"
            static let hqAny: LocalizedStringKey = "itemSearch.filter.hq.any"
            static let hqOnly: LocalizedStringKey = "itemSearch.filter.hq.only"
            static let hqExclude: LocalizedStringKey = "itemSearch.filter.hq.exclude"
            static let tradable: LocalizedStringKey = "itemSearch.filter.tradable.section"
            static let tradableAny: LocalizedStringKey = "itemSearch.filter.tradable.any"
            static let tradableOnly: LocalizedStringKey = "itemSearch.filter.tradable.only"
            static let tradableExclude: LocalizedStringKey = "itemSearch.filter.tradable.exclude"
            static let category: LocalizedStringKey = "itemSearch.filter.category.section"
            static let jobs: LocalizedStringKey = "itemSearch.filter.jobs.section"
            static let equipSlot: LocalizedStringKey = "itemSearch.filter.equipSlot.section"

            static func itemLevelRange(lowerBound: Int, upperBound: Int) -> LocalizedStringKey {
                "itemSearch.filter.itemLevel.range \(lowerBound) \(upperBound)"
            }

            static func rarityAccessibility(_ name: String) -> LocalizedStringKey {
                "itemSearch.filter.rarity.accessibility \(name)"
            }
        }

        enum Market {
            static let section: LocalizedStringKey = "itemSearch.market.section"
            static let scope: LocalizedStringKey = "itemSearch.market.scope"
            static let loading: LocalizedStringKey = "itemSearch.market.loading"
            static let untradable: LocalizedStringKey = "itemSearch.market.untradable"
            static let empty: LocalizedStringKey = "itemSearch.market.empty"
            static let nqLowestPrice: LocalizedStringKey = "itemSearch.market.metric.nqLowestPrice"
            static let currentLowestPrice: LocalizedStringKey = "itemSearch.market.metric.currentLowestPrice"
            static let hqLowestPrice: LocalizedStringKey = "itemSearch.market.metric.hqLowestPrice"
            static let recentAveragePrice: LocalizedStringKey = "itemSearch.market.metric.recentAveragePrice"
            static let openUniversalis: LocalizedStringKey = "itemSearch.market.openUniversalis"
            static let listings: LocalizedStringKey = "itemSearch.market.listings.section"
            static let emptyListings: LocalizedStringKey = "itemSearch.market.listings.empty"
            static let recentSales: LocalizedStringKey = "itemSearch.market.recentSales.section"
            static let emptyRecentSales: LocalizedStringKey = "itemSearch.market.recentSales.empty"

            static func lastUpdated(_ dateText: String) -> LocalizedStringKey {
                "itemSearch.market.lastUpdated \(dateText)"
            }

            static func showAllListings(count: Int) -> LocalizedStringKey {
                "itemSearch.market.listings.showAll \(count)"
            }
        }

        enum Recipe {
            static let section: LocalizedStringKey = "itemSearch.recipe.section"
            static let unavailable: LocalizedStringKey = "itemSearch.recipe.unavailable"
            static let loading: LocalizedStringKey = "itemSearch.recipe.loading"
            static let specialRecipe: LocalizedStringKey = "itemSearch.recipe.specialRecipe"

            static func resultAmount(_ amount: Int) -> LocalizedStringKey {
                "itemSearch.recipe.resultAmount \(amount)"
            }

            static func fallbackItem(id: Int) -> String {
                String(localized: "itemSearch.recipe.fallbackItem \(id)")
            }
        }

        enum Gathering {
            static let section: LocalizedStringKey = "itemSearch.gathering.section"
            static let showAll: LocalizedStringKey = "itemSearch.gathering.showAll"
            static let collapse: LocalizedStringKey = "itemSearch.gathering.collapse"
            static let showAllHint: LocalizedStringKey = "itemSearch.gathering.showAllHint"
            static let collapseHint: LocalizedStringKey = "itemSearch.gathering.collapseHint"
            static let openFishingGuide: LocalizedStringKey = "itemSearch.gathering.openFishingGuide"
            static let openFishingGuideHint: LocalizedStringKey = "itemSearch.gathering.openFishingGuideHint"
        }
    }
}
