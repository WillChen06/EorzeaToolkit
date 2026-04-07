import Foundation

enum LocalDataService {
    enum LoadError: Error, LocalizedError {
        case fileNotFound(String)
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                return "找不到資料檔案：\(name).json"
            case .decodingFailed(let error):
                return "資料解析失敗：\(error.localizedDescription)"
            }
        }
    }

    static func load<T: Decodable>(_ filename: String) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw LoadError.fileNotFound(filename)
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as DecodingError {
            throw LoadError.decodingFailed(error)
        }
    }
}
