import Foundation

/// Command-line options. Paths default to the files in the repository, found from `--root`.
struct EvalOptions {
    struct InvalidArguments: Error {
        let message: String
    }

    static let usage = """
    用法：ItemQueryEval [--check] [--root <repo>] [--items <items.json>] [--cases <cases.json>]
      --check   只檢查評估集，不呼叫模型
      --root    repo 的根目錄，預設是目前的目錄
      --items   道具資料，預設是 <root>/EorzeaToolkit/Resources/Data/items.json
      --cases   評估集，預設是 <root>/Tools/ItemQueryEval/cases.json
    """

    let checkOnly: Bool
    let itemsURL: URL
    let casesURL: URL

    /// Accepts both `--name value` and `--name=value`; the Xcode scheme passes `--root=…`.
    init(arguments: [String]) throws {
        var checkOnly = false
        var root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        var itemsURL: URL?
        var casesURL: URL?

        var remaining = arguments[...]
        while let argument = remaining.popFirst() {
            let (name, inlineValue) = Self.split(argument)
            switch name {
            case "--check":
                checkOnly = true
            case "--root", "--items", "--cases":
                guard let value = inlineValue ?? remaining.popFirst() else {
                    throw InvalidArguments(message: "\(name) 後面要接路徑")
                }
                let url = URL(fileURLWithPath: value)
                switch name {
                case "--root": root = url
                case "--items": itemsURL = url
                default: casesURL = url
                }
            default:
                throw InvalidArguments(message: "不認得的參數：\(argument)")
            }
        }

        self.checkOnly = checkOnly
        self.itemsURL = itemsURL ?? root.appendingPathComponent("EorzeaToolkit/Resources/Data/items.json")
        self.casesURL = casesURL ?? root.appendingPathComponent("Tools/ItemQueryEval/cases.json")
    }

    private static func split(_ argument: String) -> (name: String, value: String?) {
        guard argument.hasPrefix("--"), let separator = argument.firstIndex(of: "=") else {
            return (argument, nil)
        }
        return (String(argument[..<separator]), String(argument[argument.index(after: separator)...]))
    }
}
