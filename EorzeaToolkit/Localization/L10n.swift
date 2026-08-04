import SwiftUI

enum L10n {
    enum Common {
        static let clear: LocalizedStringKey = "common.clear"
        static let collapse: LocalizedStringKey = "common.collapse"
        static let done: LocalizedStringKey = "common.done"
        static let retry: LocalizedStringKey = "common.retry"
        static let reset: LocalizedStringKey = "common.reset"
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

    enum MiniCactpot {
        static let title: LocalizedStringKey = "miniCactpot.title"
        static let selectNumber: LocalizedStringKey = "miniCactpot.selectNumber"

        static func progressNeedMore(openedCount: Int, remainingCount: Int) -> LocalizedStringKey {
            "miniCactpot.progress.needMore \(openedCount) \(remainingCount)"
        }

        static func progressReady(openedCount: Int) -> LocalizedStringKey {
            "miniCactpot.progress.ready \(openedCount)"
        }

        static func lineName(_ line: MiniCactpotLine) -> LocalizedStringKey {
            LocalizedStringKey(line.nameKey)
        }

        static func lineNameText(_ line: MiniCactpotLine) -> String {
            String(localized: String.LocalizationValue(stringLiteral: line.nameKey))
        }

        enum Result {
            static let allLines: LocalizedStringKey = "miniCactpot.result.allLines"

            static func recommendation(lineName: String) -> LocalizedStringKey {
                "miniCactpot.result.recommendation \(lineName)"
            }

            static func expectedValue(_ expectedValue: String) -> LocalizedStringKey {
                "miniCactpot.result.expectedValue \(expectedValue)"
            }
        }

        enum Payout {
            static let title: LocalizedStringKey = "miniCactpot.payout.title"
            static let sum: LocalizedStringKey = "miniCactpot.payout.sum"
            static let reward: LocalizedStringKey = "miniCactpot.payout.reward"
        }

        enum Cell {
            static let empty: LocalizedStringKey = "miniCactpot.cell.empty"
            static let selectHint: LocalizedStringKey = "miniCactpot.cell.selectHint"

            static func number(_ number: Int) -> LocalizedStringKey {
                "miniCactpot.cell.number \(number)"
            }
        }
    }

    enum TreasureMap {
        static let title: LocalizedStringKey = "treasureMap.title"
        static let loadFailedTitle: LocalizedStringKey = "treasureMap.loadFailedTitle"
        static let emptyTitle: LocalizedStringKey = "treasureMap.emptyTitle"
        static let emptyDescription: LocalizedStringKey = "treasureMap.emptyDescription"
        static let loading: LocalizedStringKey = "treasureMap.loading"
        static let gatheringNodes: LocalizedStringKey = "treasureMap.gatheringNodes"

        static func level(_ level: Int) -> LocalizedStringKey {
            "treasureMap.level \(level)"
        }

        static func expansion(_ expansion: String) -> LocalizedStringKey {
            "treasureMap.expansion \(expansion)"
        }

        static func selectMap(count: Int) -> LocalizedStringKey {
            "treasureMap.selectMap \(count)"
        }

        static func spotCount(_ count: Int) -> LocalizedStringKey {
            "treasureMap.spotCount \(count)"
        }

        static func gatheringSheetTitle(grade: String, name: String, level: Int) -> LocalizedStringKey {
            "treasureMap.gathering.title \(grade) \(name) \(level)"
        }

        static func jobSection(jobLabel: String, count: Int) -> LocalizedStringKey {
            "treasureMap.gathering.jobSection \(jobLabel) \(count)"
        }

        static func coordinatePair(x: String, y: String) -> LocalizedStringKey {
            "treasureMap.coordinates.pair \(x) \(y)"
        }

        static func coordinatesXY(x: String, y: String) -> LocalizedStringKey {
            "treasureMap.coordinates.xy \(x) \(y)"
        }

        static func nodeMapTitle(zoneName: String, typeName: String) -> LocalizedStringKey {
            "treasureMap.gathering.nodeMapTitle \(zoneName) \(typeName)"
        }

        static func nodeType(_ typeName: String) -> LocalizedStringKey {
            "treasureMap.gathering.nodeType \(typeName)"
        }

        static func nodeCoordinates(x: String, y: String) -> LocalizedStringKey {
            "treasureMap.gathering.nodeCoordinates \(x) \(y)"
        }

        static func unknownRegion(id: Int) -> String {
            String(localized: "treasureMap.unknownRegion.id \(id)")
        }

        static var unknownRegionText: String {
            String(localized: "treasureMap.unknownRegion")
        }

        enum MapType {
            static var soloText: String {
                String(localized: "treasureMap.mapType.solo")
            }

            static var partyText: String {
                String(localized: "treasureMap.mapType.party")
            }
        }

        enum GatheringJob {
            static var minerText: String {
                String(localized: "treasureMap.gathering.job.miner")
            }

            static var botanistText: String {
                String(localized: "treasureMap.gathering.job.botanist")
            }
        }

        enum GatheringNode {
            static var mineralDepositText: String {
                String(localized: "treasureMap.gathering.node.mineralDeposit")
            }

            static var rockyOutcropText: String {
                String(localized: "treasureMap.gathering.node.rockyOutcrop")
            }

            static var matureTreeText: String {
                String(localized: "treasureMap.gathering.node.matureTree")
            }

            static var lushVegetationText: String {
                String(localized: "treasureMap.gathering.node.lushVegetation")
            }

            static var unknownText: String {
                String(localized: "treasureMap.gathering.node.unknown")
            }
        }
    }

    enum RelicWeapon {
        static let title: LocalizedStringKey = "relicWeapon.title"
        static let loadFailedTitle: LocalizedStringKey = "relicWeapon.loadFailedTitle"
        static let emptyTitle: LocalizedStringKey = "relicWeapon.emptyTitle"
        static let emptyDescription: LocalizedStringKey = "relicWeapon.emptyDescription"
        static let loading: LocalizedStringKey = "relicWeapon.loading"
        static let latest: LocalizedStringKey = "relicWeapon.latest"
        static let mode: LocalizedStringKey = "relicWeapon.mode"
        static let modeView: LocalizedStringKey = "relicWeapon.mode.view"
        static let modeTracking: LocalizedStringKey = "relicWeapon.mode.tracking"
        static let stagesSection: LocalizedStringKey = "relicWeapon.stages.section"
        static let job: LocalizedStringKey = "relicWeapon.job"
        static let progress: LocalizedStringKey = "relicWeapon.progress"
        static let quest: LocalizedStringKey = "relicWeapon.quest"
        static let materials: LocalizedStringKey = "relicWeapon.materials"
        static let noExtraMaterials: LocalizedStringKey = "relicWeapon.materials.none"
        static let markComplete: LocalizedStringKey = "relicWeapon.tracking.markComplete"
        static let markIncomplete: LocalizedStringKey = "relicWeapon.tracking.markIncomplete"
        static let showNote: LocalizedStringKey = "relicWeapon.materials.note.show"
        static let hideNote: LocalizedStringKey = "relicWeapon.materials.note.hide"
        static let itemLevelUnavailable: LocalizedStringKey = "relicWeapon.itemLevel.unavailable"

        static func level(_ level: Int) -> LocalizedStringKey {
            "relicWeapon.level \(level)"
        }

        static func stageCount(_ count: Int) -> LocalizedStringKey {
            "relicWeapon.stageCount \(count)"
        }

        static func jobCount(_ count: Int) -> LocalizedStringKey {
            "relicWeapon.jobCount \(count)"
        }

        static func seriesTitle(shortName: String, fullName: String) -> LocalizedStringKey {
            "relicWeapon.series.title \(shortName) \(fullName)"
        }

        static func stage(_ index: Int) -> LocalizedStringKey {
            "relicWeapon.stage \(index)"
        }

        static func progressSummary(completedCount: Int, totalCount: Int, percentage: Int) -> LocalizedStringKey {
            "relicWeapon.progress.summary \(completedCount) \(totalCount) \(percentage)"
        }

        static func itemLevel(_ itemLevel: Int) -> LocalizedStringKey {
            "relicWeapon.itemLevel \(itemLevel)"
        }

        static func jobName(_ abbreviation: String) -> LocalizedStringKey {
            switch abbreviation {
            case "PLD":
                return "relicWeapon.job.pld"
            case "WAR":
                return "relicWeapon.job.war"
            case "DRK":
                return "relicWeapon.job.drk"
            case "GNB":
                return "relicWeapon.job.gnb"
            case "WHM":
                return "relicWeapon.job.whm"
            case "SCH":
                return "relicWeapon.job.sch"
            case "AST":
                return "relicWeapon.job.ast"
            case "SGE":
                return "relicWeapon.job.sge"
            case "MNK":
                return "relicWeapon.job.mnk"
            case "DRG":
                return "relicWeapon.job.drg"
            case "NIN":
                return "relicWeapon.job.nin"
            case "SAM":
                return "relicWeapon.job.sam"
            case "RPR":
                return "relicWeapon.job.rpr"
            case "VPR":
                return "relicWeapon.job.vpr"
            case "BRD":
                return "relicWeapon.job.brd"
            case "MCH":
                return "relicWeapon.job.mch"
            case "DNC":
                return "relicWeapon.job.dnc"
            case "BLM":
                return "relicWeapon.job.blm"
            case "SMN":
                return "relicWeapon.job.smn"
            case "RDM":
                return "relicWeapon.job.rdm"
            case "PCT":
                return "relicWeapon.job.pct"
            default:
                assertionFailure("Unhandled relic weapon job abbreviation: \(abbreviation)")
                return LocalizedStringKey(abbreviation)
            }
        }
    }
}
