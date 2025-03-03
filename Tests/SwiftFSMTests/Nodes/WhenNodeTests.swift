import Testing
@testable import SwiftFSM

final class WhenNodeTests: SyntaxNodeTests {
    @Test func emptyWhenNode() {
        assertEmptyNodeWithError(WhenNode(events: [], rest: []))
    }
    
    @Test func emptyWhenNodeWithActions() {
        assertEmptyNodeWithError(WhenNode(events: [], rest: [thenNode]))
    }
    
    @Test func emptyWhenBlockNodeWithActions() {
        assertEmptyNodeWithError(WhenBlockNode(events: [e1]))
    }
    
    @Test func emptyWhenBlockNodeHasNoOutput() {
        #expect(WhenBlockNode(events: [e1]).resolve().output.isEmpty)
    }
    
    @Test func whenNodeWithEmptyRest() async {
        await assertWhen(
            state: nil,
            actionsCount: 0,
            actionsOutput: "",
            node: WhenNode(events: [e1, e2], rest: [])
        )
    }
    
    func assertWhenNodeWithActions(
        expected: String = "1212",
        _ w: WhenNode,
        location: SourceLocation = #_sourceLocation
    ) async {
        await assertWhen(
            state: s1,
            actionsCount: 2,
            actionsOutput: expected,
            node: w,
            location: location
        )
    }
    
    @Test func whenNodeFinalisesCorrectly() async {
        await assertWhenNodeWithActions(WhenNode(events: [e1, e2], rest: [thenNode]))
    }
    
    @Test func whenNodeWithChainFinalisesCorrectly() async throws {
        let w = WhenNode(events: [e3])
        try await assertDefaultIONodeChains(node: w, expectedEvent: e3)
    }
    
    @Test func whenNodeCanSetRestAfterInit() async {
        let w = WhenNode(events: [e1, e2])
        w.rest.append(thenNode)
        await assertWhenNodeWithActions(w)
    }
}
