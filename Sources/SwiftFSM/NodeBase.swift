//
//  Nodes.swift
//
//  Created by Daniel Segall on 20/02/2023.
//

import Foundation

protocol NodeBase {
    associatedtype Input
    associatedtype Output
    
    func validate() -> [Error]
    func combinedWithRest(_ rest: [Input]) -> [Output]
}

extension NodeBase {
    func validate() -> [Error] { [] }
}

protocol UnsafeNode: NodeBase {
    var rest: [any UnsafeNode] { get set }
    func finalised() throws -> ([Output], [Error])
}

@available(macOS 13, iOS 16, *)
protocol Node<Output>: NodeBase {
    var rest: [any Node<Input>] { get set }
    func finalised() -> ([Output], [Error])
}

extension UnsafeNode {
    func finalised() throws -> ([Output], [Error]) {
        var output = [Input]()
        var errors = [Error]()
        
        try rest.forEach {
            guard let finalised = try $0.finalised() as? ([Input], [Error]) else {
                throw """
Error: \(type(of: try $0.finalised().0)) must equal Array<\(Input.self)>
    Self: \(type(of: self))
    Rest: \(rest.isEmpty ? "nil" : String(describing: type(of: rest.first!)))
"""
            }
            output.append(contentsOf: finalised.0)
            errors.append(contentsOf: finalised.1)
        }
        
        return (combinedWithRest(output), validate() + errors)
    }
}

@available(macOS 13, iOS 16, *)
extension Node {
    func finalised() -> ([Output], [Error]) {
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


