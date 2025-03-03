import Testing
@testable import SwiftFSM

class NodeTests {
    struct StringNode: SyntaxNode {
        let first: String
        var rest: [any SyntaxNode<String>]

        func findErrors() -> [Error] { ["E"] }

        func combineWith(_ rest: [String]) -> [String] {
            rest.reduce(into: []) {
                $0.append(first + $1)
            } ??? [first]
        }
    }

    
    func assertEqual<T: Equatable, E: Error>(
        actual: ([T], [E])?,
        expected: ([T], [E])?,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(actual?.0 == expected?.0, sourceLocation: location)
        #expect(
            actual?.1.map(\.localizedDescription) == expected?.1.map(\.localizedDescription),
            sourceLocation: location
        )
    }

    @Test func safeNodesCallCombineWithRestRecursively() {
        let n0 = StringNode(first: "Then1", rest: [])
        let n1 = StringNode(first: "Then2", rest: [])
        let n2 = StringNode(first: "When", rest: [n0, n1])
        let n3 = StringNode(first: "Given", rest: [n2])
        
        assertEqual(actual: n3.resolve(),
                    expected: (["GivenWhenThen1", "GivenWhenThen2"],
                               ["E", "E", "E", "E"]))
    }
    
    @Test func resolveCallsCombinedWithBeforeValidate() {
        class NodeSpy: SyntaxNode {
            var rest: [any SyntaxNode<String>] = []
            
            var log = [String]()
            
            func findErrors() -> [Error] {
                log.append("second call")
                return []
            }
            
            func combineWith(_ rest: [String]) -> [String] {
                log.append("first call")
                return []
            }
        }
        
        let n = NodeSpy()
        let _ = n.resolve()
        #expect(n.log == ["first call", "second call"])
    }
}

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
