import SwiftUI

struct ItemDetailView: View {
    let item: Item
    let itemsByID: [Int: Item]

    @Environment(MarketPriceSettings.self) private var marketPriceSettings

    @State private var recipes: [Recipe]?
    @State private var gatheringNodes: [ItemGatheringNode] = []
    @State private var selectedRecipeItem: Item?
    @State private var marketPriceViewModel = MarketPriceViewModel()

    init(item: Item, itemsByID: [Int: Item] = [:]) {
        self.item = item
        self.itemsByID = itemsByID
    }

    var body: some View {
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

            MarketPriceSection(item: item, viewModel: marketPriceViewModel)

            RecipeSection(
                recipes: recipes,
                itemsByID: itemsByID,
                onSelectIngredient: { selectedRecipeItem = $0 }
            )

            GatheringSection(nodes: gatheringNodes)

            Section("後續擴充") {
                Label("取得方式聚合與用途反查將在後續 Phase 補上", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRecipeItem) { item in
            ItemDetailView(item: item, itemsByID: itemsByID)
        }
        .task(id: marketPriceLoadTaskID) {
            marketPriceViewModel.load(item: item, scope: marketPriceSettings.selectedScope)
        }
        .task(id: item.id) {
            recipes = nil
            gatheringNodes = []
            async let loadedRecipes = RecipeDataService.recipes(for: item.id)
            async let loadedGatheringNodes = GatheringDataService.nodes(for: item.id)
            recipes = await loadedRecipes
            gatheringNodes = await loadedGatheringNodes
        }
    }

    private var marketPriceLoadTaskID: String {
        "\(item.id)-\(marketPriceSettings.selectedScope.id)"
    }
}
