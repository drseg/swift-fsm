//
//  NodeTests.swift
//
//  Created by Daniel Segall on 20/02/2023.
//

import XCTest
@testable import SwiftFSM

protocol Addable { static func + (lhs: Self, rhs: Self) -> Self }
extension String: Addable {}; extension Int: Addable {}

class NodeTests: XCTestCase {
    class GenericNode<NodeType, IOType: Addable> {
        var first: IOType
        var rest: [NodeType]
        
        init(first: IOType, rest: [NodeType]) {
            self.first = first
            self.rest = rest
        }
        
        func validate() -> [Error] {
            ["E"]
        }
        
        func combinedWithRest(_ rest: [IOType]) -> [IOType] {
            rest.reduce(into: [IOType]()) {
                $0.append(first + $1)
            } ??? [first]
        }
    }
    
    func assertEqual<T: Equatable, E: Error>(
        actual: ([T], [E])?,
        expected: ([T], [E])?,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual?.0, expected?.0, line: line)
        XCTAssertEqual(actual?.1.map(\.localizedDescription),
                       expected?.1.map(\.localizedDescription), line: line)
    }
    
    @available(macOS 13, iOS 16, *)
    class SafeStringNode: GenericNode<any Node<String>, String>, Node { }
    class UnsafeStringNode: GenericNode<UnsafeNode, String>, UnsafeNode, Nameable { }
    
    @available(macOS 13, iOS 16, *)
    func testSafeNodesCallCombineWithRestRecursively() {
        let n0 = SafeStringNode(first: "Then1", rest: [])
        let n1 = SafeStringNode(first: "Then2", rest: [])
        let n2 = SafeStringNode(first: "When", rest: [n0, n1])
        let n3 = SafeStringNode(first: "Given", rest: [n2])
        
        assertEqual(actual: n3.finalised(),
                    expected: (["GivenWhenThen1", "GivenWhenThen2"],
                               ["E", "E", "E", "E"]))
    }
    
    func testUnsafeNodesCallCombineWithRestRecursively() {
        let n0 = UnsafeStringNode(first: "Then1", rest: [])
        let n1 = UnsafeStringNode(first: "Then2", rest: [])
        let n2 = UnsafeStringNode(first: "When", rest: [n0, n1])
        let n3 = UnsafeStringNode(first: "Given", rest: [n2])
        
        assertEqual(actual: try? n3.finalised(),
                    expected: (["GivenWhenThen1", "GivenWhenThen2"],
                               ["E", "E", "E", "E"]))
    }
    
    func testUnsafeNodeThrowsErrorIfOutputInputTypeMismatch() {
        class IntNode: GenericNode<UnsafeNode, Int>, UnsafeNode, Nameable {}
        
        let n1 = IntNode(first: 1, rest: [])
        let n2 = UnsafeStringNode(first: "1", rest: [n1])
        
        XCTAssertThrowsError(try n2.finalised().0) {
            if let error = $0 as? String {
                XCTAssertTrue(error.contains(UnsafeStringNode.name))
                XCTAssertTrue(error.contains(IntNode.name))
            } else {
                XCTFail("Wrong error")
            }
        }
    }
}

protocol Nameable { }; extension Nameable {
    static var name: String {
        String(describing: Self.self)
    }
}

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
