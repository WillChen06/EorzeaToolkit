import SwiftUI

struct RecipeSection: View {
    let recipes: [Recipe]?
    let itemsByID: [Int: Item]
    let onSelectIngredient: (Item) -> Void

    var body: some View {
        Section(L10n.ItemSearch.Recipe.section) {
            if let recipes {
                if recipes.isEmpty {
                    Label(L10n.ItemSearch.Recipe.unavailable, systemImage: "hammer")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                } else {
                    ForEach(recipes, id: \.self) { recipe in
                        RecipeCard(
                            recipe: recipe,
                            itemsByID: itemsByID,
                            onSelectIngredient: onSelectIngredient
                        )
                    }
                }
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)

                    Text(L10n.ItemSearch.Recipe.loading)
                }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
        .appThemedListRow()
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
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    RecipeIngredientRow(
                        ingredient: ingredient,
                        item: itemsByID[ingredient.itemID],
                        onSelect: onSelectIngredient
                    )

                    if ingredient != recipe.ingredients.last {
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
            if let craftJob = recipe.craftJob {
                Text(craftJob)
                    .font(.headline)
            } else {
                Text(L10n.ItemSearch.Recipe.specialRecipe)
                    .font(.headline)
            }

            Text(levelText)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)

            Spacer(minLength: 12)

            if recipe.resultAmount > 1 {
                Text(L10n.ItemSearch.Recipe.resultAmount(recipe.resultAmount))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.surfaceDepth, in: Capsule())
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
        L10n.ItemSearch.Recipe.fallbackItem(id: ingredient.itemID)
    }

    private func rowContent(name: String, item: Item?) -> some View {
        HStack(spacing: 12) {
            if let item {
                ItemIconView(item: item, size: 32)
            } else {
                Image(systemName: "questionmark.square")
                    .font(.title3)
                    .foregroundStyle(AppTheme.mutedInk)
                    .frame(width: 32, height: 32)
            }

            Text(name)
                .font(.subheadline)
                .foregroundStyle(item == nil ? AppTheme.mutedInk : AppTheme.ink)
                .lineLimit(2)

            Spacer(minLength: 8)

            Text("×\(ingredient.amount)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(AppTheme.mutedInk)
        }
        .accessibilityElement(children: .combine)
    }
}
