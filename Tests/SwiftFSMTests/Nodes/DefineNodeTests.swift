import XCTest
@testable import SwiftFSM

final class DefineNodeTests: SyntaxNodeTests {
    func testEmptyDefineNodeProducesError() {
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
    
    func testDefineNodeWithActionsButNoRestProducesError() {
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
    
    func testCompleteNodeWithInvalidMatchProducesErrorAndNoOutput() {
        let invalidMatch = MatchDescriptor(all: P.a, P.a)
        
        let m = MatchingNode(descriptor: invalidMatch, rest: [WhenNode(events: [e1])])
        let g = GivenNode(states: [s1], rest: [m])
        let d = DefineNode(onEntry: [], onExit: [], rest: [g])
        
        let result = d.resolved()
        
        XCTAssertEqual(0, result.output.count)
        XCTAssertEqual(1, result.errors.count)
        XCTAssertTrue(result.errors.first is MatchError)
    }
    
    func testDefineNodeWithNoActions() {
        let d = DefineNode(onEntry: [],
                           onExit: [],
                           rest: [givenNode(thenState: s3,
                                            actionsNode: ActionsNode(actions: []))])
        
        let expected = [MSES(m1, s1, e1, s3),
                        MSES(m1, s1, e2, s3),
                        MSES(m1, s2, e1, s3),
                        MSES(m1, s2, e2, s3)]
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    func testDefineNodeCanSetRestAfterInit() {
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
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    func testDefineNodeWithMultipleGivensWithEntryActionsAndExitActions() {
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
        
        assertDefineNode(
            expected: expected,
            actionsOutput: "<<12>><<12>><<12>><<12>><<12>><<12>><<12>><<12>>",
            node: d
        )
    }
    
    func testDefineNodeDoesNotAddEntryAndExitActionsIfStateDoesNotChange() {
        let d = DefineNode(onEntry: onEntry,
                           onExit: onExit,
                           rest: [givenNode(thenState: nil,
                                            actionsNode: actionsNode)])
        
        let expected = [MSES(m1, s1, e1, s1),
                        MSES(m1, s1, e2, s1),
                        MSES(m1, s2, e1, s2),
                        MSES(m1, s2, e2, s2)]
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    func testDefineNodePassesGroupIDAndIsOverrideParams() {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1], rest: [t])
        let m = MatchingNode(descriptor: m1, rest: [w], overrideGroupID: testGroupID, isOverride: true)
        let g = GivenNode(states: [s1], rest: [m])
        let output = DefineNode(onEntry: [], onExit: [], rest: [g]).resolved().output
        
        XCTAssert(output.allSatisfy { $0.overrideGroupID == testGroupID && $0.isOverride == true })
    }
}
