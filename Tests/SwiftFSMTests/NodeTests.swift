//
//  Playground.swift
//  
//
//  Created by Daniel Segall on 20/02/2023.
//

import XCTest
@testable import SwiftFSM

final class NodeTests: XCTestCase {
    class StringNodeBase {
        typealias Value = String
        typealias Input = String
        typealias Output = String
        
        var first: String
        
        init(first: String) {
            self.first = first
        }

        func combineWithRest(_ rest: [String]) -> [String] {
            rest.reduce(into: [String]()) {
                $0.append(first + $1)
            } ??? [first]
        }
    }
    
    @available(macOS 13, iOS 16, *)
    class StringNode: StringNodeBase, Node {
        var rest: [any Node<Input>]
        
        init(first: String, rest: [any Node<Input>]) {
            self.rest = rest
            super.init(first: first)
        }
    }
    
    class UnsafeStringNode: StringNodeBase, UnsafeNode {
        var rest: [any UnsafeNode]
        
        init(first: String, rest: [any UnsafeNode]) {
            self.rest = rest
            super.init(first: first)
        }
    }
    
    func assertNodes<N: NodeBase>(
        _ n0: N,
        _ n1: N,
        _ n2: N,
        _ n3: N,
        _ output: [String],
        _ line: UInt = #line
    ) {
        XCTAssertEqual(output, ["GivenWhenThen1", "GivenWhenThen2"], line: line)
        
        XCTAssertEqual(Set([n1, n2, n3]).count, 3, line: line)
        XCTAssertEqual(Set([n1, n1, n1]).count, 1, line: line)
        
        XCTAssertEqual(n2, n2, line: line)
        XCTAssertNotEqual(n1, n2, line: line)
    }

    @available(macOS 13, iOS 16, *)
    func testSafe() {
        let n0 = StringNode(first: "Then1", rest: [])
        let n1 = StringNode(first: "Then2", rest: [])
        let n2 = StringNode(first: "When", rest: [n0, n1])
        let n3 = StringNode(first: "Given", rest: [n2])
        
        assertNodes(n0, n1, n2, n3, n3.finalise())
    }
    
    func testUnsafe() {
        let n0 = UnsafeStringNode(first: "Then1", rest: [])
        let n1 = UnsafeStringNode(first: "Then2", rest: [])
        let n2 = UnsafeStringNode(first: "When", rest: [n0, n1])
        let n3 = UnsafeStringNode(first: "Given", rest: [n2])

        assertNodes(n0, n1, n2, n3, try! n3.finalise())
    }
    
    func testUnsafeErrors() {
        struct IntNode: UnsafeNode {
            typealias Value = Int
            typealias Input = Int
            typealias Output = Int
            
            var first: Int
            var rest: [any UnsafeNode]
            
            func combineWithRest(_ rest: [Int]) -> [Int] {
                [first]
            }
        }
        
        let n1 = IntNode(first: 1, rest: [])
        let n2 = UnsafeStringNode(first: "1", rest: [n1])
        
        XCTAssertThrowsError(try n2.finalise()) {
            if let error = $0 as? String {
                XCTAssertTrue(error.contains("UnsafeStringNode"))
                XCTAssertTrue(error.contains("IntNode"))
            } else {
                XCTFail("Wrong error")
            }
        }
    }
}

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
