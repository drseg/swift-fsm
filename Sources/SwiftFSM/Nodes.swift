//
//  Nodes.swift
//
//  Created by Daniel Segall on 20/02/2023.
//

import Foundation

protocol NodeBase {
    associatedtype Input
    associatedtype Output
        
    func combinedWithRest(_ rest: [Input]) -> [Output]
}

protocol UnsafeNode: NodeBase {
    var rest: [any UnsafeNode] { get }
    func finalised() throws -> [Output]
}

@available(macOS 13, iOS 16, *)
protocol Node<Output>: NodeBase {
    var rest: [any Node<Input>] { get }
    func finalised() -> [Output]
}

extension UnsafeNode {
    func finalised() throws -> [Output] {
        try combinedWithRest(rest.reduce(into: [Input]()) {
            guard let finalised = try $1.finalised() as? [Input] else {
                throw """
Error: \(type(of: try $1.finalised())) must equal Array<\(Input.self)>
    Self: \(type(of: self))
    Rest: \(rest.isEmpty ? "nil" : String(describing: type(of: rest.first!)))
"""
            }
            
            $0.append(contentsOf: finalised)
        })
    }
}

@available(macOS 13, iOS 16, *)
extension Node {
    func finalised() -> [Output] {
        combinedWithRest(
            rest.reduce(into: [Input]()) {
                $0.append(contentsOf: $1.finalised())
            }
        )
    }
}

extension String: Error { }


