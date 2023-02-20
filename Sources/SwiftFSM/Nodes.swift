//
//  File.swift
//  
//
//  Created by Daniel Segall on 20/02/2023.
//

import Foundation

protocol NodeBase: Hashable {
    associatedtype Value: Hashable
    associatedtype Input: Hashable
    associatedtype Output: Hashable
    
    var first: Value { get }
    
    func combineWithRest(_ rest: [Input]) -> [Output]
}

extension NodeBase {
    func isEqual(to rhs: any NodeBase) -> Bool {
        guard let rhs = rhs as? Self else { return false }
        return self == rhs
    }
}

protocol UnsafeNode: NodeBase {
    var rest: [any UnsafeNode] { get }
    func finalise() throws -> [Output]
}

extension UnsafeNode {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.first == rhs.first &&
        zip(lhs.rest, rhs.rest).allSatisfy {
            $0.0.isEqual(to: $0.1)
        }
    }
    
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(first)
        rest.forEach {
            $0.hash(into: &hasher)
        }
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
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.first == rhs.first &&
        zip(lhs.rest, rhs.rest).allSatisfy {
            $0.0.isEqual(to: $0.1)
        }
    }
    
    func finalise() -> [Output] {
        combineWithRest(rest.reduce(into: [Input]()) {
            $0.append(contentsOf: $1.finalise())
        })
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(first)
        rest.forEach {
            $0.hash(into: &hasher)
        }
    }
}
