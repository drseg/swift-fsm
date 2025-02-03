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
    
    func testMatchNodeFinalisesCorrectly() async {
        await assertMatch(MatchingNode(descriptor: MatchDescriptorChain(), rest: [whenNode]))
    }
    
    func testMatchNodeWithChainFinalisesCorrectly() async {
        let m = MatchingNode(descriptor: MatchDescriptorChain(any: S.b, all: R.a))
        await assertDefaultIONodeChains(node: m, expectedMatch: MatchDescriptorChain(any: [[P.a], [S.b]],
                                                                                     all: Q.a, R.a))
    }
    
    func testMatchNodeCanSetRestAfterInit() async {
        let m = MatchingNode(descriptor: MatchDescriptorChain())
        m.rest.append(whenNode)
        await assertMatch(m)
    }
}
