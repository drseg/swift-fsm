import Foundation

protocol NodeBase {
    associatedtype Input
    associatedtype Output
    
    typealias Result = (output: [Output], errors: [Error])
    
    func finalised() -> Result
    func combinedWithRest(_ rest: [Input]) -> [Output]
    func validate() -> [Error]
    
    var _rest: [any NodeBase] { get }
}

extension NodeBase {
    func finalised() -> Result {
        var output = [Input](), errors = [Error]()
        
        _rest.forEach {
            if let finalised = $0.finalised() as? ([Input], [Error])  {
                output.append(contentsOf: finalised.0)
                errors.append(contentsOf: finalised.1)
            } else {
                errors.append(errorMessage($0))
            }
        }
        
        return (combinedWithRest(output), validate() + errors)
    }
    
    func errorMessage(_ n: any NodeBase) -> String {
        """
        Error: \(type(of: n.finalised().0)) must equal Array<\(Input.self)>
            Self: \(type(of: self))
            Rest: \(_rest.isEmpty ? "nil" : String(describing: type(of: _rest.first!)))
        """
    }
    
    func validate() -> [Error] { [] }
}

protocol UnsafeNode: NodeBase {
    var rest: [any UnsafeNode] { get set }
}

@available(macOS 13, iOS 16, *)
protocol Node<Output>: NodeBase {
    var rest: [any Node<Input>] { get set }
}

extension UnsafeNode {
    var _rest: [any NodeBase] { rest }
}

@available(macOS 13, iOS 16, *)
extension Node {
    var _rest: [any NodeBase] { rest }
}

extension String: LocalizedError {
    public var errorDescription: String? { self }
}


