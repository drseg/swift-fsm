import XCTest
@testable import SwiftFSM

final class WhenNodeTests: SyntaxNodeTests {
    func testEmptyWhenNode() {
        assertEmptyNodeWithError(WhenNode(events: [], rest: []))
    }
    
    func testEmptyWhenNodeWithActions() {
        assertEmptyNodeWithError(WhenNode(events: [], rest: [thenNode]))
    }
    
    func testEmptyWhenBlockNodeWithActions() {
        assertEmptyNodeWithError(WhenBlockNode(events: [e1]))
    }
    
    func testEmptyWhenBlockNodeHasNoOutput() {
        assertCount(WhenBlockNode(events: [e1]).resolve().output, expected: 0)
    }
    
    func testWhenNodeWithEmptyRest() async {
        await assertWhen(
            state: nil,
            actionsCount: 0,
            actionsOutput: "",
            node: WhenNode(events: [e1, e2], rest: []),
            line: #line
        )
    }
    
    func assertWhenNodeWithActions(
        expected: String = "1212",
        _ w: WhenNode,
        line: UInt = #line
    ) async {
        await assertWhen(
            state: s1,
            actionsCount: 2,
            actionsOutput: expected,
            node: w,
            line: line
        )
    }
    
    func testWhenNodeFinalisesCorrectly() async {
        await assertWhenNodeWithActions(WhenNode(events: [e1, e2], rest: [thenNode]))
    }
    
    func testWhenNodeWithChainFinalisesCorrectly() async {
        let w = WhenNode(events: [e3])
        await assertDefaultIONodeChains(node: w, expectedEvent: e3)
    }
    
    func testWhenNodeCanSetRestAfterInit() async {
        let w = WhenNode(events: [e1, e2])
        w.rest.append(thenNode)
        await assertWhenNodeWithActions(w)
    }
}
