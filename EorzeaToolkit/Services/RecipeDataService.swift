import Foundation

enum RecipeDataService {
    private static let cache = RecipeDataCache()

    static func recipes(for itemID: Int) async -> [Recipe] {
        await cache.recipes(for: itemID)
    }
}

private actor RecipeDataCache {
    private var recipesByResultID: [String: [Recipe]]?

    func recipes(for itemID: Int) -> [Recipe] {
        if let recipesByResultID {
            return recipesByResultID[String(itemID), default: []]
        }

        do {
            let data: RecipeDataResponse = try LocalDataService.load("recipes")
            recipesByResultID = data.recipes
            return data.recipes[String(itemID), default: []]
        } catch {
            recipesByResultID = [:]
            return []
        }
    }
}
