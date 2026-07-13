import SwiftUI

struct ItemDetailView: View {
    let item: Item
    let itemsByID: [Int: Item]

    @Environment(MarketPriceSettings.self) private var marketPriceSettings

    @State private var recipes: [Recipe]?
    @State private var gatheringNodes: [ItemGatheringNode] = []
    @State private var fishingSpots: [ItemFishingSpot] = []
    @State private var shopEntry: ItemShopEntry?
    @State private var selectedRecipeItem: Item?
    @State private var marketPriceViewModel = MarketPriceViewModel()

    init(item: Item, itemsByID: [Int: Item] = [:]) {
        self.item = item
        self.itemsByID = itemsByID
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    VStack(spacing: 16) {
                        ItemIconView(item: item, size: 96)

                        VStack(spacing: 6) {
                            Text(item.displayName)
                                .font(.title2.weight(.semibold))
                                .multilineTextAlignment(.center)

                            Text("iLv \(item.ilvl)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                ObtainSourceSection(sources: obtainSources) { source in
                    withAnimation {
                        proxy.scrollTo(source, anchor: .top)
                    }
                }

                if let recipes, !recipes.isEmpty {
                    RecipeSection(
                        recipes: recipes,
                        itemsByID: itemsByID,
                        onSelectIngredient: { selectedRecipeItem = $0 }
                    )
                    .id(ObtainSource.recipe)
                }

                if hasGatheringSources {
                    GatheringSection(nodes: gatheringNodes, fishingSpots: fishingSpots)
                        .id(ObtainSource.gathering)
                }

                if let shopEntry, shopEntry.isShopPurchase {
                    ShopPurchaseSection(entry: shopEntry)
                        .id(ObtainSource.shop)
                }

                if !item.isUntradable {
                    MarketPriceSection(item: item, viewModel: marketPriceViewModel)
                        .id(ObtainSource.market)
                }
            }
            .navigationTitle(item.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedRecipeItem) { item in
                ItemDetailView(item: item, itemsByID: itemsByID)
            }
            .onChange(of: marketPriceLoadTaskID, initial: true) {
                if !item.isUntradable {
                    marketPriceViewModel.load(item: item, scope: marketPriceSettings.selectedScope)
                }
            }
            .task(id: item.id) {
                recipes = nil
                gatheringNodes = []
                fishingSpots = []
                shopEntry = nil
                async let loadedRecipes = RecipeDataService.recipes(for: item.id)
                async let loadedGatheringNodes = GatheringDataService.nodes(for: item.id)
                async let loadedFishingSpots = FishingDataService.spots(for: item.id)
                async let loadedShopEntry = ItemShopDataService.shopEntry(for: item.id)
                recipes = await loadedRecipes
                gatheringNodes = await loadedGatheringNodes
                fishingSpots = await loadedFishingSpots
                shopEntry = await loadedShopEntry
            }
        }
    }

    private var marketPriceLoadTaskID: String {
        "\(item.id)-\(marketPriceSettings.selectedScope.id)"
    }

    private var hasGatheringSources: Bool {
        !gatheringNodes.isEmpty || !fishingSpots.isEmpty
    }

    private var obtainSources: [ObtainSource] {
        ObtainSource.allCases.filter { source in
            switch source {
            case .recipe:
                return recipes?.isEmpty == false
            case .gathering:
                return hasGatheringSources
            case .shop:
                return shopEntry?.isShopPurchase == true
            case .market:
                return !item.isUntradable
            }
        }
    }
}
