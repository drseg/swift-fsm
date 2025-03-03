import Testing
@testable import SwiftFSM

final class ThenNodeTests: SyntaxNodeTests {
    @Test func nilThenNodeState() throws {
        try assertEmptyThen(ThenNode(state: nil, rest: []), thenState: nil)
    }
    
    @Test func emptyThenNode() throws {
        try assertEmptyThen(ThenNode(state: s1, rest: []))
    }
    
    @Test func thenNodeWithEmptyRest() throws {
        try assertEmptyThen(ThenNode(state: s1, rest: [ActionsNode(actions: [])]))
    }
    
    @Test func emptyThenBlockNodeIsError() {
        assertEmptyNodeWithError(ThenBlockNode(state: s1, rest: []))
    }
    
    @Test func emptyThenBlockNodeHasNoOutput() {
        #expect(ThenBlockNode(state: s1, rest: []).resolve().output.isEmpty)
    }
    
    @Test func thenNodeFinalisesCorrectly() async {
        await assertThenWithActions(
            expected: "12",
            ThenNode(state: s1, rest: [actionsNode])
        )
    }
    
    @Test func thenNodePlusChainFinalisesCorrectly() async throws {
        let t = ThenNode(state: s2)
        try await assertDefaultIONodeChains(node: t, expectedState: s2)
    }
    
    @Test func thenNodeCanSetRestAfterInit() async {
        let t = ThenNode(state: s1)
        t.rest.append(actionsNode)
        await assertThenWithActions(expected: "12", t)
    }
    
    @Test func thenNodeFinalisesWithMultipleActionsNodes() async {
        await assertThenWithActions(
            expected: "1212",
            ThenNode(
                state: s1,
                rest: [actionsNode, actionsNode]
            )
        )
    }
}
