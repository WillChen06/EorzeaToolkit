import Foundation

// Evaluates how well the on-device model turns a Traditional Chinese sentence into item search
// conditions, using the same parsing code as the app. See prompts/item-query-eval.md.
//
// Exits 0 once every case has been asked, blocked or failed cases included; 1 when the input
// files are wrong or the model cannot be used; 2 for bad arguments.

func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

extension Duration {
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}

let options: EvalOptions
do {
    options = try EvalOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch let error as EvalOptions.InvalidArguments {
    printError(error.message)
    printError(EvalOptions.usage)
    exit(2)
} catch {
    printError("\(error)")
    exit(2)
}

let itemData: ItemDataResponse
do {
    itemData = try JSONDecoder().decode(ItemDataResponse.self, from: Data(contentsOf: options.itemsURL))
} catch {
    printError("讀不到道具資料 \(options.itemsURL.path)：\(error)")
    exit(1)
}

let vocabulary = ItemQueryVocabulary(data: itemData)
let loaded = EvalCaseLoader.load(from: options.casesURL, vocabulary: vocabulary)
if !loaded.problems.isEmpty {
    printError("評估集有 \(loaded.problems.count) 個問題：")
    for problem in loaded.problems {
        printError("  - \(problem)")
    }
    exit(1)
}

if options.checkOnly {
    print(EvalReport.composition(loaded.cases))
    print("評估集檢查通過。")
    exit(0)
}

let status = ItemQueryModelStatus.current()
guard status == .available else {
    printError(EvalReport.unavailableMessage(status))
    exit(1)
}

let parser: ItemQueryParser
do {
    parser = try ItemQueryParser(vocabulary: vocabulary)
} catch {
    printError("無法建立解析用的 schema：\(error)")
    exit(1)
}

var outcomes: [EvalOutcome] = []
let clock = ContinuousClock()
for (index, evalCase) in loaded.cases.enumerated() {
    printError("[\(index + 1)/\(loaded.cases.count)] \(evalCase.id)")

    let start = clock.now
    let result: EvalOutcome.Result
    do {
        let query = try await parser.query(for: evalCase.query)
        result = .parsed(query)
    } catch {
        let message = String(describing: error)
        result = ItemQueryParser.isGuardrailViolation(error) ? .blocked(message) : .failed(message)
    }

    outcomes.append(EvalOutcome(
        evalCase: evalCase,
        expected: vocabulary.resolve(evalCase.expected),
        result: result,
        seconds: start.duration(to: clock.now).seconds
    ))
}

print(EvalReport.text(outcomes: outcomes, vocabulary: vocabulary))
exit(0)
