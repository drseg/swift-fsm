import XCTest
@testable import SwiftFSM

final class ActionsNodeTests: SyntaxNodeTests {
    func testEmptyActions() {
        let finalised = ActionsNode(actions: [], rest: []).resolved()
        let output = finalised.output
        let errors = finalised.errors
        
        XCTAssertTrue(errors.isEmpty)
        guard assertCount(output, expected: 1) else { return }
        assertEqual(DefaultIO(MatchDescriptor(), nil, nil, actions), output.first)
    }
    
    func testEmptyActionsBlockIsError() {
        assertEmptyNodeWithError(ActionsBlockNode(actions: [], rest: []))
    }
    
    func testEmptyActionsBlockHasNoOutput() {
        assertCount(ActionsBlockNode(actions: [], rest: []).resolved().output, expected: 0)
    }
    
    @MainActor
    func testActionsFinalisesCorrectly() {
        let n = actionsNode
        n.resolved().output.executeAll()
        XCTAssertEqual("12", actionsOutput)
        XCTAssertTrue(n.resolved().errors.isEmpty)
    }
    
    func testActionsPlusChainFinalisesCorrectly() {
        let actions = [{ self.actionsOutput += "action" }]
        let a = ActionsNode(actions: actions.map(AnyAction.init))
        assertDefaultIONodeChains(node: a, expectedOutput: "actionchain")
    }
}
