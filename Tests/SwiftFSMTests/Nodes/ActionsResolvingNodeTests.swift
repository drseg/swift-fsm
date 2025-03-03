import Testing
@testable import SwiftFSM

class ActionsResolvingNodeTests: DefineConsumer {
    @Test func emptyNode() {
        let node = ActionsResolvingNode.OnStateChange()
        let finalised = node.resolve()
        #expect(finalised.output.isEmpty)
        #expect(finalised.errors.isEmpty)
    }
    
    func assertNode<T: ActionsResolvingNode>(
        type: T.Type,
        g: AnyTraceable,
        m: MatchDescriptorChain,
        w: AnyTraceable,
        t: AnyTraceable,
        output: String,
        location: SourceLocation = #_sourceLocation
    ) async throws {
        let node = T.init(rest: [defineNode(g, m, w, t, exit: onExit)])
        let finalised = node.resolve()
        #expect(finalised.errors.isEmpty, sourceLocation: location)
        try #require(finalised.output.count == 1, sourceLocation: location)
        
        let result = finalised.output[0]
        await assertResult(result, g, m, w, t, output, location)
    }
    
    func assertResult(
        _ result: ActionsResolvingNode.OnStateChange.Output,
        _ g: AnyTraceable,
        _ m: MatchDescriptorChain,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        _ output: String,
        _ location: SourceLocation = #_sourceLocation

    ) async {
        #expect(result.state == g, sourceLocation: location)
        #expect(result.descriptor == m, sourceLocation: location)
        #expect(result.event == w, sourceLocation: location)
        #expect(result.nextState == t, sourceLocation: location)
        #expect(result.overrideGroupID == testGroupID, sourceLocation: location)
        #expect(!result.isOverride, sourceLocation: location)
        
        await assertActions(result.actions, expectedOutput: output, location: location)
    }
    
    let m = MatchDescriptorChain()
    
    @Test func conditionalDoesNotAddExitActionsWithoutStateChange() async throws{
        try await assertNode(type: ActionsResolvingNode.OnStateChange.self,
                             g: s1, m: m, w: e1, t: s1, output: "12")
    }
    
    @Test func unconditionalAddsExitActionsWithoutStateChange() async throws {
        try await assertNode(type: ActionsResolvingNode.ExecuteAlways.self,
                             g: s1, m: m, w: e1, t: s1, output: "12>>")
    }
    
    @Test func conditionalAddsExitActionsWithStateChange() async throws {
        try await assertNode(type: ActionsResolvingNode.OnStateChange.self,
                             g: s1, m: m, w: e1, t: s2, output: "12>>")
    }
    
    @Test func conditionalDoesNotAddEntryActionsWithoutStateChange() async throws {
        let d1 = defineNode(s1, m, e1, s1, entry: onEntry, exit: [])
        let result = ActionsResolvingNode.OnStateChange(rest: [d1]).resolve()
        
        #expect(result.errors.isEmpty)
        try #require(result.output.count == 1)
        await assertResult(result.output[0], s1, m, e1, s1, "12")
    }
    
    @Test func unconditionalAddsEntryActionsWithoutStateChange() async throws {
        let d1 = defineNode(s1, m, e1, s1, entry: onEntry, exit: onExit)
        let result = ActionsResolvingNode.ExecuteAlways(rest: [d1]).resolve()
        
        #expect(result.errors.isEmpty)
        try #require(result.output.count == 1)
        await assertResult(result.output[0], s1, m, e1, s1, "12>><<")
    }
    
    @Test func conditionalAddsEntryActionsForStateChange() async throws {
        let d1 = defineNode(s1, m, e1, s2)
        let d2 = defineNode(s2, m, e1, s3, entry: onEntry, exit: onExit)
        let result = ActionsResolvingNode.OnStateChange(rest: [d1, d2]).resolve()
        
        #expect(result.errors.isEmpty)
        try #require(result.output.count == 2)
        
        await assertResult(result.output[0], s1, m, e1, s2, "12<<")
        await assertResult(result.output[1], s2, m, e1, s3, "12>>")
    }
}
