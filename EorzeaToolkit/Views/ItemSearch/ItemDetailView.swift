import SwiftUI

struct ItemDetailView: View {
    let item: Item
    let itemsByID: [Int: Item]

    @State private var recipes: [Recipe] = []
    @State private var selectedRecipeItem: Item?

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

            MarketPriceSection(item: item)

            RecipeSection(
                recipes: recipes,
                itemsByID: itemsByID,
                onSelectIngredient: { selectedRecipeItem = $0 }
            )

            Section("後續擴充") {
                Label("取得方式、採集與用途反查將在後續 Phase 補上", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRecipeItem) { item in
            ItemDetailView(item: item, itemsByID: itemsByID)
        }
        .task(id: item.id) {
            recipes = await RecipeDataService.recipes(for: item.id)
        }
    }
}
