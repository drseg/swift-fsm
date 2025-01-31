import XCTest
@testable import SwiftFSM

final class MatchNodeTests: SyntaxNodeTests {
    func testEmptyMatchNodeIsNotError() {
        assertCount(MatchingNode(descriptor: MatchDescriptor(), rest: []).resolved().errors, expected: 0)
    }
    
    func testEmptyMatchBlockNodeIsError() {
        assertEmptyNodeWithError(MatchingBlockNode(descriptor: MatchDescriptor(), rest: []))
    }
    
    func testEmptyMatchBlockNodeHasNoOutput() {
        assertCount(MatchingBlockNode(descriptor: MatchDescriptor(), rest: []).resolved().output, expected: 0)
    }
    
    func testMatchNodeFinalisesCorrectly() {
        assertMatch(MatchingNode(descriptor: MatchDescriptor(), rest: [whenNode]))
    }
    
    func testMatchNodeWithChainFinalisesCorrectly() {
        let m = MatchingNode(descriptor: MatchDescriptor(any: S.b, all: R.a))
        assertDefaultIONodeChains(node: m, expectedMatch: MatchDescriptor(any: [[P.a], [S.b]],
                                                                all: Q.a, R.a))
    }
    
    func testMatchNodeCanSetRestAfterInit() {
        let m = MatchingNode(descriptor: MatchDescriptor())
        m.rest.append(whenNode)
        assertMatch(m)
    }
}
