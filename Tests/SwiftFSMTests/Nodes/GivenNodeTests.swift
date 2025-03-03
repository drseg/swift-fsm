import Testing
@testable import SwiftFSM

final class GivenNodeTests: SyntaxNodeTests {
    @Test func emptyGivenNode() {
        assertEmptyNodeWithoutError(GivenNode(states: [], rest: []))
    }
    
    @Test func givenNodeWithEmptyStates() {
        assertEmptyNodeWithoutError(GivenNode(states: [], rest: [whenNode]))
    }
    
    @Test func givenNodeWithEmptyRest() {
        assertEmptyNodeWithoutError(GivenNode(states: [s1, s2], rest: []))
    }
    
    @Test func givenNodeFinalisesFillingInEmptyNextStates() async {
        let expected = [MSES(m1, s1, e1, s1),
                        MSES(m1, s1, e2, s1),
                        MSES(m1, s2, e1, s2),
                        MSES(m1, s2, e2, s2)]
        
        await assertGivenNode(expected: expected,
                              actionsOutput: "12121212",
                              node: givenNode(thenState: nil, actionsNode: actionsNode))
    }
    
    @Test func givenNodeFinalisesWithNextStates() async {
        let expected = [MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES (m1, s2, e2, s3)]
        
        await assertGivenNode(expected: expected,
                              actionsOutput: "12121212",
                              node: givenNode(thenState: s3, actionsNode: actionsNode))
    }
    
    @Test func givenNodeCanSetRestAfterInitialisation() async {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchingNode(descriptor: m1, rest: [w])
        var g = GivenNode(states: [s1, s2])
        g.rest.append(m)
        
        let expected = [MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES(m1, s2, e2, s3)]
        
        await assertGivenNode(expected: expected,
                              actionsOutput: "12121212",
                              node: g)
    }
    
    @Test func givenNodeWithMultipleWhenNodes() async {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchingNode(descriptor: m1, rest: [w, w])
        let g = GivenNode(states: [s1, s2], rest: [m])
        
        let expected = [MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES(m1, s2, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES(m1, s2, e2, s3)]
        
        await assertGivenNode(expected: expected,
                              actionsOutput: "1212121212121212",
                              node: g)
    }
    
    @Test func givenNodePassesGroupIDAndIsOverrideParams() {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1], rest: [t])
        let m = MatchingNode(descriptor: m1, rest: [w], overrideGroupID: testGroupID, isOverride: true)
        let output = GivenNode(states: [s1], rest: [m]).resolve().output
        
        #expect(output.allSatisfy { $0.overrideGroupID == testGroupID && $0.isOverride == true })
    }
}
