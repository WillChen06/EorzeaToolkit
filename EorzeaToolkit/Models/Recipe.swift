import Foundation

struct RecipeDataResponse: Decodable, Sendable {
    let recipes: [String: [Recipe]]
}

struct Recipe: Decodable, Hashable, Sendable {
    let recipeNumber: Int
    let craftType: Int
    let craftJob: String?
    let recipeLevel: Int
    let stars: Int
    let resultAmount: Int
    let ingredients: [RecipeIngredient]

    enum CodingKeys: String, CodingKey {
        case ingredients
        case recipeNumber = "recipe_number"
        case craftType = "craft_type"
        case craftJob = "craft_job"
        case recipeLevel = "recipe_level"
        case stars
        case resultAmount = "result_amount"
    }
}

struct RecipeIngredient: Decodable, Hashable, Sendable {
    let itemID: Int
    let amount: Int
    let resolvable: Bool

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case amount
        case resolvable
    }
}
