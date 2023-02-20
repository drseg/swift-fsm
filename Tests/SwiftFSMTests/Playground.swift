//
//  Playground.swift
//  
//
//  Created by Daniel Segall on 20/02/2023.
//

import XCTest

@available(macOS 13.0.0, *)
protocol Node<Output>: Hashable {
    associatedtype Value: Hashable
    associatedtype Input: Hashable
    associatedtype Output: Hashable
    
    var first: Value { get }
    var rest: [any Node<Input>] { get }
    
    func finalise() -> Output
}

@available(macOS 13.0.0, *)
extension Node {
    func makeInput() -> [Input] {
        rest.reduce(into: [Input]()) {
            $0.append($1.finalise())
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.first == rhs.first &&
        zip(lhs.rest, rhs.rest).allSatisfy {
            $0.0.isEqual(to: $0.1)
        }
    }
    
    func isEqual(to rhs: any Node) -> Bool {
        guard let rhs = rhs as? Self else { return false }
        return self == rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(first)
        rest.forEach {
            $0.hash(into: &hasher)
        }
    }
}

@available(macOS 13.0.0, *)
final class Playground: XCTestCase {
    class StringNode: Node {
        typealias Value = String
        typealias Input = String
        typealias Output = String

        var first: String
        var rest: [any Node<String>]
        
        func finalise() -> String {
            fatalError("subclasses must implement")
        }
        
        init(first: String, rest: [any Node<String>]) {
            self.first = first
            self.rest = rest
        }
    }
    
    class DefineNode: StringNode {
        override func finalise() -> String {
            makeInput().reduce(into: [String]()) {
                $0.append(first + $1)
            }.joined(separator: "-")
        }
    }
    
    class WhenNode: StringNode {
        override func finalise() -> String {
            first + makeInput().joined()
        }
    }
    
    class ThenNode: StringNode {
        override func finalise() -> String {
            first + makeInput().joined()
        }
    }
    
    func test() {
        let n1 = ThenNode(first: "Then", rest: [])
        let n2 = WhenNode(first: "When", rest: [n1])
        let n3 = DefineNode(first: "Given", rest: [n2, n2])
        
        XCTAssertEqual(n3.finalise(), "GivenWhenThen-GivenWhenThen")
        XCTAssertEqual(Set([n1, n2, n3]).count, 3)
        XCTAssertEqual(Set([n1, n1, n1]).count, 1)
    }
}
