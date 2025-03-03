import Testing
@testable import SwiftFSM

final class DefineNodeTests: SyntaxNodeTests {
    @Test func emptyDefineNodeProducesError() {
        assertEmptyNodeWithError(
            DefineNode(
                onEntry: [],
                onExit: [],
                rest: [],
                caller: "caller",
                file: "file",
                line: 10
            )
        )
    }
    
    @Test func defineNodeWithActionsButNoRestProducesError() {
        assertEmptyNodeWithError(
            DefineNode(
                onEntry: [AnyAction({ })],
                onExit: [AnyAction({ })],
                rest: [],
                caller: "caller",
                file: "file",
                line: 10
            )
        )
    }
    
    @Test func completeNodeWithInvalidMatchProducesErrorAndNoOutput() {
        let invalidMatch = MatchDescriptorChain(all: P.a, P.a)
        
        let m = MatchingNode(descriptor: invalidMatch, rest: [WhenNode(events: [e1])])
        let g = GivenNode(states: [s1], rest: [m])
        let d = DefineNode(onEntry: [], onExit: [], rest: [g])
        
        let result = d.resolve()
        
        #expect(0 == result.output.count)
        #expect(1 == result.errors.count)
        #expect(result.errors.first is MatchError)
    }
    
    @Test func defineNodeWithNoActions() async {
        let d = DefineNode(onEntry: [],
                           onExit: [],
                           rest: [givenNode(thenState: s3,
                                            actionsNode: ActionsNode(actions: []))])
        
        let expected = [MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES(m1, s2, e2, s3)]
        
        await assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    @Test func defineNodeCanSetRestAfterInit() async {
        let t = ThenNode(state: s3, rest: [])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchingNode(descriptor: m1, rest: [w])
        let g = GivenNode(states: [s1, s2], rest: [m])
        
        let d = DefineNode(onEntry: [],
                           onExit: [])
        d.rest.append(g)
        
        let expected = [MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES(m1, s2, e2, s3)]
        
        await assertDefineNode(
            expected: expected,
            actionsOutput: "",
            node: d
        )
    }
    
    @Test func defineNodeWithMultipleGivensWithEntryActionsAndExitActions() async {
        let d = DefineNode(onEntry: onEntry,
                           onExit: onExit,
                           rest: [givenNode(thenState: s3,
                                            actionsNode: actionsNode),
                                  givenNode(thenState: s3,
                                            actionsNode: actionsNode)])
        
        let expected = [MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES(m1, s2, e2, s3),
                        MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES(m1, s2, e2, s3)]
        
        await assertDefineNode(
            expected: expected,
            actionsOutput: "<<12>><<12>><<12>><<12>><<12>><<12>><<12>><<12>>",
            node: d
        )
    }
    
    @Test func defineNodeDoesNotAddEntryAndExitActionsIfStateDoesNotChange() async {
        let d = DefineNode(onEntry: onEntry,
                           onExit: onExit,
                           rest: [givenNode(thenState: nil,
                                            actionsNode: actionsNode)])
        
        let expected = [MSES(m1, s1, e1, s1),
                        MSES(m1, s1, e2, s1),
                        MSES(m1, s2, e1, s2),
                        MSES(m1, s2, e2, s2)]
        
        await assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    @Test func defineNodePassesGroupIDAndIsOverrideParams() {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1], rest: [t])
        let m = MatchingNode(descriptor: m1, rest: [w], overrideGroupID: testGroupID, isOverride: true)
        let g = GivenNode(states: [s1], rest: [m])
        let output = DefineNode(onEntry: [], onExit: [], rest: [g]).resolve().output
        
        #expect(output.allSatisfy { $0.overrideGroupID == testGroupID && $0.isOverride == true })
    }
}
