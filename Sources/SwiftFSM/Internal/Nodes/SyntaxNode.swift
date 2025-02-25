import Foundation

protocol SyntaxNode<Output> {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    typealias Result = (output: [Output], errors: [Error])
    
    var rest: [any SyntaxNode<Input>] { get set }

    func combinedWith(_ rest: [Input]) -> [Output]
    func findErrors() -> [Error]
}

extension SyntaxNode {
    func resolve() -> Result {
        var allOutput = [Input]()
        var allErrors = [Error]()

        rest.forEach {
            let resolved = $0.resolve()
            allOutput.append(contentsOf: resolved.output)
            allErrors.append(contentsOf: resolved.errors)
        }

        return (combinedWith(allOutput), findErrors() + allErrors)
    }

    func findErrors() -> [Error] { [] }
}
