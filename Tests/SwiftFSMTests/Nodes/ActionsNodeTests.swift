import XCTest
@testable import SwiftFSM

final class ActionsNodeTests: SyntaxNodeTests {
    func testEmptyActions() {
        let finalised = ActionsNode(actions: [], rest: []).resolve()
        let output = finalised.output
        let errors = finalised.errors
        
        XCTAssertTrue(errors.isEmpty)
        guard assertCount(output, expected: 1) else { return }
        assertEqual(RawSyntaxDTO(MatchDescriptorChain(), nil, nil, actions), output.first)
    }
    
    func testEmptyActionsBlockIsError() {
        assertEmptyNodeWithError(ActionsBlockNode(actions: [], rest: []))
    }
    
    func testEmptyActionsBlockHasNoOutput() {
        assertCount(ActionsBlockNode(actions: [], rest: []).resolve().output, expected: 0)
    }
    
    func testActionsFinalisesCorrectly() async {
        let n = actionsNode
        await n.resolve().output.executeAll()
        XCTAssertEqual("12", actionsOutput)
        XCTAssertTrue(n.resolve().errors.isEmpty)
    }
    
    func testActionsPlusChainFinalisesCorrectly() async {
        let a = ActionsNode(actions: [AnyAction({ self.actionsOutput += "action" })])
        await assertDefaultIONodeChains(node: a, expectedOutput: "actionchain")
    }
}
