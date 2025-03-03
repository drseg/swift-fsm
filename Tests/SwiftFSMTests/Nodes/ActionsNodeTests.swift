import Testing
@testable import SwiftFSM

final class ActionsNodeTests: SyntaxNodeTests {
    @Test func emptyActions() throws {
        let finalised = ActionsNode(actions: [], rest: []).resolve()
        let output = finalised.output
        let errors = finalised.errors
        
        #expect(errors.isEmpty)
        try #require(output.count == 1)
        assertEqual(RawSyntaxDTO(MatchDescriptorChain(), nil, nil, actions), output.first)
    }
    
    @Test func emptyActionsBlockIsError() {
        assertEmptyNodeWithError(ActionsBlockNode(actions: [], rest: []))
    }
    
    @Test func emptyActionsBlockHasNoOutput() {
        #expect(ActionsBlockNode(actions: [], rest: []).resolve().output.isEmpty)
    }
    
    @Test func actionsFinalisesCorrectly() async {
        let n = actionsNode
        await n.resolve().output.executeAll()
        #expect("12" == actionsOutput)
        #expect(n.resolve().errors.isEmpty)
    }
    
    @Test func actionsPlusChainFinalisesCorrectly() async throws {
        let a = ActionsNode(actions: [AnyAction({ self.actionsOutput += "action" })])
        try await assertDefaultIONodeChains(node: a, expectedOutput: "actionchain")
    }
}
