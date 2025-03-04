import Testing
@testable import SwiftFSM

final class MatchingNodeTests: SyntaxNodeTests {
    @Test func emptyMatchNodeIsNotError() {
        #expect(
            MatchingNode(
                descriptor: MatchDescriptorChain(), rest: []
            ).resolve().errors.isEmpty
        )
    }
    
    @Test func emptyMatchBlockNodeIsError() {
        assertEmptyNodeWithError(
            MatchingBlockNode(
                descriptor: MatchDescriptorChain(),
                rest: []
            )
        )
    }
    
    @Test func emptyMatchBlockNodeHasNoOutput() {
        #expect(
            MatchingBlockNode(
                descriptor: MatchDescriptorChain(),
                rest: []
            ).resolve().output.isEmpty
        )
    }
    
    @Test func matchNodeFinalisesCorrectly() async throws  {
        try await assertMatch(MatchingNode(descriptor: MatchDescriptorChain(), rest: [whenNode]))
    }
    
    @Test func matchNodeWithChainFinalisesCorrectly() async throws {
        let m = MatchingNode(descriptor: MatchDescriptorChain(any: S.b, all: R.a))
        try await assertDefaultIONodeChains(
            node: m,
            expectedMatch: MatchDescriptorChain(any: [[P.a], [S.b]],
                                                all: Q.a, R.a)
        )
    }
    
    @Test func matchNodeCanSetRestAfterInit() async throws {
        let m = MatchingNode(descriptor: MatchDescriptorChain())
        m.rest.append(whenNode)
        try await assertMatch(m)
    }
}
