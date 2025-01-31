import XCTest
@testable import SwiftFSM

final class ActionsNodeTests: SyntaxNodeTests {
    func testEmptyActions() {
        let finalised = ActionsNode(actions: [], rest: []).resolve()
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
        assertCount(ActionsBlockNode(actions: [], rest: []).resolve().output, expected: 0)
    }
    
    @MainActor
    func testActionsFinalisesCorrectly() {
        let n = actionsNode
        n.resolve().output.executeAll()
        XCTAssertEqual("12", actionsOutput)
        XCTAssertTrue(n.resolve().errors.isEmpty)
    }
    
    func testActionsPlusChainFinalisesCorrectly() {
        let actions = [{ self.actionsOutput += "action" }]
        let a = ActionsNode(actions: actions.map(AnyAction.init))
        assertDefaultIONodeChains(node: a, expectedOutput: "actionchain")
    }
}
