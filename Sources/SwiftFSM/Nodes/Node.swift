import Foundation

protocol Node<Output> {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    typealias Result = (output: [Output], errors: [Error])

    func resolve() -> Result
    func validate() -> [Error]

    func combinedWithRest(_ rest: [Input]) -> [Output]
    var rest: [any Node<Input>] { get set }
}

extension Node {
    func resolve() -> Result {
        var output = [Input]()
        var errors = [Error]()

        rest.forEach {
            let finalised = $0.resolve()
            output.append(contentsOf: finalised.0)
            errors.append(contentsOf: finalised.1)
        }

        return (combinedWithRest(output), validate() + errors)
    }

    func validate() -> [Error] { [] }
}
