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
    
    func finalise() -> [Output]
    func combineWithRest(_ rest: [Input]) -> [Output]
}

@available(macOS 13.0.0, *)
extension Node {
    func finalise() -> [Output] {
        combineWithRest(rest.reduce(into: [Input]()) {
            $0.append(contentsOf: $1.finalise())
        })
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

        init(first: String, rest: [any Node<String>]) {
            self.first = first
            self.rest = rest
        }
        
        func combineWithRest(_ rest: [String]) -> [String] {
            rest.reduce(into: [String]()) {
                $0.append(first + $1)
            } ??? [first]
        }
    }

    func test() {
        let n1 = StringNode(first: "Then", rest: [])
        let n2 = StringNode(first: "When", rest: [n1])
        let n3 = StringNode(first: "Given", rest: [n2])

        XCTAssertEqual(n3.finalise(), ["GivenWhenThen"])
        XCTAssertEqual(Set([n1, n2, n3]).count, 3)
        XCTAssertEqual(Set([n1, n1, n1]).count, 1)
    }
}

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
