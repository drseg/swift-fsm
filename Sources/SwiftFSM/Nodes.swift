//
//  File.swift
//  
//
//  Created by Daniel Segall on 20/02/2023.
//

import Foundation

protocol NodeBase {
    associatedtype Input
    associatedtype Output
        
    func combineWithRest(_ rest: [Input]) -> [Output]
}

protocol UnsafeNode: NodeBase {
    var rest: [any UnsafeNode] { get }
    func finalise() throws -> [Output]
}

extension UnsafeNode {
    func finalise() throws -> [Output] {
        try combineWithRest(rest.reduce(into: [Input]()) {
            guard let finalised = try $1.finalise() as? [Input] else {
                throw """
Error: \(type(of: try $1.finalise())) must equal Array<\(Input.self)>
    Self: \(type(of: self))
    Rest: \(rest.isEmpty ? "nil" : String(describing: type(of: rest.first!)))
"""
            }
            
            $0.append(contentsOf: finalised)
        })
    }
}

extension String: Error { }

@available(macOS 13, iOS 16, *)
protocol Node<Output>: NodeBase {
    var rest: [any Node<Input>] { get }
    func finalise() -> [Output]
}

@available(macOS 13, iOS 16, *)
extension Node {
    func finalise() -> [Output] {
        combineWithRest(rest.reduce(into: [Input]()) {
            $0.append(contentsOf: $1.finalise())
        })
    }
}
