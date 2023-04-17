import XCTest
@testable import SwiftFSM

final class MatchNodeTests: SyntaxNodeTests {
    func testEmptyMatchNodeIsNotError() {
        assertCount(MatchNode(match: Match(), rest: []).finalised().errors, expected: 0)
    }
    
    func testEmptyMatchBlockNodeIsError() {
        assertEmptyNodeWithError(MatchBlockNode(match: Match(), rest: []))
    }
    
    func testEmptyMatchBlockNodeHasNoOutput() {
        assertCount(MatchBlockNode(match: Match(), rest: []).finalised().output, expected: 0)
    }
    
    func testMatchNodeFinalisesCorrectly() {
        assertMatch(MatchNode(match: Match(), rest: [whenNode]))
    }
    
    func testMatchNodeWithChainFinalisesCorrectly() {
        let m = MatchNode(match: Match(any: S.b, all: R.a))
        assertDefaultIONodeChains(node: m, expectedMatch: Match(any: [[P.a], [S.b]],
                                                                all: Q.a, R.a))
    }
    
    func testMatchNodeCanSetRestAfterInit() {
        let m = MatchNode(match: Match())
        m.rest.append(whenNode)
        assertMatch(m)
    }
}
