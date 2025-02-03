import XCTest
@testable import SwiftFSM

class NodeTests: XCTestCase {
    struct StringNode: Node {
        let first: String
        var rest: [any Node<String>]

        func validate() -> [Error] { ["E"] }

        func combinedWith(_ rest: [String]) -> [String] {
            rest.reduce(into: []) {
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
    

    func testSafeNodesCallCombineWithRestRecursively() {
        let n0 = StringNode(first: "Then1", rest: [])
        let n1 = StringNode(first: "Then2", rest: [])
        let n2 = StringNode(first: "When", rest: [n0, n1])
        let n3 = StringNode(first: "Given", rest: [n2])
        
        assertEqual(actual: n3.resolve(),
                    expected: (["GivenWhenThen1", "GivenWhenThen2"],
                               ["E", "E", "E", "E"]))
    }
    
    // FIXME: Currently, there is a temporal coupling between Node.combinedWith() and Node.validate() - validate() cannot find all errors until combinedWith() has already been called. This test protects this arrangement until a better solution can be implemented
    func testResolveCallsCombinedWithBeforeValidate() {
        class NodeSpy: Node {
            var rest: [any Node<String>] = []
            
            var log = [String]()
            
            func validate() -> [Error] {
                log.append(#function)
                return []
            }
            
            func combinedWith(_ rest: [String]) -> [String] {
                log.append(#function)
                return []
            }
        }
        
        let n = NodeSpy()
        let _ = n.resolve()
        
        XCTAssertEqual(n.log, ["combinedWith(_:)", "validate()"])
    }
}

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
