import XCTest
@testable import SwiftFSM

final class MatchingNodeTests: SyntaxNodeTests {
    func testEmptyMatchNodeIsNotError() {
        assertCount(MatchingNode(descriptor: MatchDescriptorChain(), rest: []).resolve().errors, expected: 0)
    }
    
    func testEmptyMatchBlockNodeIsError() {
        assertEmptyNodeWithError(MatchingBlockNode(descriptor: MatchDescriptorChain(), rest: []))
    }
    
    func testEmptyMatchBlockNodeHasNoOutput() {
        assertCount(MatchingBlockNode(descriptor: MatchDescriptorChain(), rest: []).resolve().output, expected: 0)
    }
    
    func testMatchNodeFinalisesCorrectly() {
        assertMatch(MatchingNode(descriptor: MatchDescriptorChain(), rest: [whenNode]))
    }
    
    func testMatchNodeWithChainFinalisesCorrectly() {
        let m = MatchingNode(descriptor: MatchDescriptorChain(any: S.b, all: R.a))
        assertDefaultIONodeChains(node: m, expectedMatch: MatchDescriptorChain(any: [[P.a], [S.b]],
                                                                               all: Q.a, R.a))
    }
    
    func testMatchNodeCanSetRestAfterInit() {
        let m = MatchingNode(descriptor: MatchDescriptorChain())
        m.rest.append(whenNode)
        assertMatch(m)
    }
}
