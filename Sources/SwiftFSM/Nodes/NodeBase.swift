//
//  Nodes.swift
//
//  Created by Daniel Segall on 20/02/2023.
//

import Foundation

protocol NodeBase {
    associatedtype Input
    associatedtype Output
    
    typealias Result = (output: [Output], errors: [Error])
    
    func finalised() -> Result
    func combinedWithRest(_ rest: [Input]) -> [Output]
    func validate() -> [Error]
}

extension NodeBase {
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
    func finalised() -> Result {
        var output = [Input]()
        var errors = [Error]()
        
        rest.forEach {
            if let finalised = $0.finalised() as? ([Input], [Error])  {
                output.append(contentsOf: finalised.0)
                errors.append(contentsOf: finalised.1)
            } else {
                errors.append(errorMessage($0))
            }
        }
        
        return (combinedWithRest(output), validate() + errors)
    }
    
    func errorMessage(_ n: any UnsafeNode) -> String {
        """
        Error: \(type(of: n.finalised().0)) must equal Array<\(Input.self)>
            Self: \(type(of: self))
            Rest: \(rest.isEmpty ? "nil" : String(describing: type(of: rest.first!)))
        """
    }
}

@available(macOS 13, iOS 16, *)
extension Node {
    func finalised() -> Result {
        var output = [Input]()
        var errors = [Error]()
        
        rest.forEach {
            let finalised = $0.finalised()
            output.append(contentsOf: finalised.0)
            errors.append(contentsOf: finalised.1)
        }
        
        return (combinedWithRest(output), validate() + errors)
    }
}

extension String: Error { }


