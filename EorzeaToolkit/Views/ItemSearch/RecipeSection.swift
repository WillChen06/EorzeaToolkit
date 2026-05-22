import SwiftUI

struct RecipeSection: View {
    let recipes: [Recipe]
    let itemsByID: [Int: Item]
    let onSelectIngredient: (Item) -> Void

    var body: some View {
        Section("配方") {
            if recipes.isEmpty {
                Label("無法製作", systemImage: "hammer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recipes.indices, id: \.self) { index in
                    RecipeCard(
                        recipe: recipes[index],
                        itemsByID: itemsByID,
                        onSelectIngredient: onSelectIngredient
                    )
                }
            }
        }
    }
}

private struct RecipeCard: View {
    let recipe: Recipe
    let itemsByID: [Int: Item]
    let onSelectIngredient: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(spacing: 0) {
                ForEach(recipe.ingredients.indices, id: \.self) { index in
                    let ingredient = recipe.ingredients[index]

                    RecipeIngredientRow(
                        ingredient: ingredient,
                        item: itemsByID[ingredient.itemID],
                        onSelect: onSelectIngredient
                    )

                    if index < recipe.ingredients.index(before: recipe.ingredients.endIndex) {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(recipe.craftJob ?? "特殊配方")
                .font(.headline)

            Text(levelText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            if recipe.resultAmount > 1 {
                Text("產出 ×\(recipe.resultAmount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private var levelText: String {
        let starText = String(repeating: "★", count: recipe.stars)

        if starText.isEmpty {
            return "Lv.\(recipe.recipeLevel)"
        }

        return "Lv.\(recipe.recipeLevel) \(starText)"
    }
}

private struct RecipeIngredientRow: View {
    let ingredient: RecipeIngredient
    let item: Item?
    let onSelect: (Item) -> Void

    var body: some View {
        Group {
            if ingredient.resolvable, let item {
                Button {
                    onSelect(item)
                } label: {
                    rowContent(name: item.displayName, item: item)
                }
                .buttonStyle(.plain)
            } else {
                rowContent(name: fallbackName, item: nil)
            }
        }
        .padding(.vertical, 8)
    }

    private var fallbackName: String {
        "道具 #\(ingredient.itemID)"
    }

    private func rowContent(name: String, item: Item?) -> some View {
        HStack(spacing: 12) {
            if let item {
                ItemIconView(item: item, size: 32)
            } else {
                Image(systemName: "questionmark.square")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }

            Text(name)
                .font(.subheadline)
                .foregroundStyle(item == nil ? .secondary : .primary)
                .lineLimit(2)

            Spacer(minLength: 8)

            Text("×\(ingredient.amount)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
