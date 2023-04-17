import XCTest
@testable import SwiftFSM

class LazyMatchResolvingNodeTests: MRNTestBase {
    typealias SVN = SemanticValidationNode
    typealias ARN = ActionsResolvingNode
    typealias LMRN = LazyMatchResolvingNode
    
    func makeSUT(rest: [any Node<DefineNode.Output>]) -> LMRN {
        .init(rest: [SVN(rest: [ARN(rest: rest)])])
    }
    
    func testInit() {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let rest = SVN(rest: [ARN(rest: [defineNode(s1, m1, e1, s2)])])
        
        assertEqualFileAndLine(rest, sut.rest.first!)
    }
    
    func testEmptyMatchOutput() {
        let sut = makeSUT(rest: [defineNode(s1, Match(), e1, s2)])
        let result = sut.finalised()
        
        guard
            assertCount(result.errors, expected: 0),
            assertCount(result.output, expected: 1)
        else { return }
        
        assertEqual(makeOutput(c: nil, g: s1, m: Match(), p: [], w: e1, t: s2),
                    result.output.first)
    }
    
    func testOutput() {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let result = sut.finalised()
        
        guard
            assertCount(result.errors, expected: 0),
            assertCount(result.output, expected: 1)
        else { return }
        
        assertEqual(makeOutput(g: s1, m: m1, p: [P.a, Q.a], w: e1, t: s2),
                    result.output.first)
    }
}
