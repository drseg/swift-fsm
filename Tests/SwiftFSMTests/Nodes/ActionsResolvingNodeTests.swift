import XCTest
@testable import SwiftFSM

class ActionsResolvingNodeTests: DefineConsumer {
    func testEmptyNode() {
        let node = ConditionalActionsResolvingNode()
        let finalised = node.finalised()
        XCTAssertTrue(finalised.output.isEmpty)
        XCTAssertTrue(finalised.errors.isEmpty)
    }
    
    func assertNode<T: ActionsResolvingNodeBase>(
        type: T.Type,
        g: AnyTraceable,
        m: Match,
        w: AnyTraceable,
        t: AnyTraceable,
        output: String,
        line: UInt = #line
    ) {
        let node = T.init(rest: [defineNode(g, m, w, t, exit: onExit)])
        let finalised = node.finalised()
        XCTAssertTrue(finalised.errors.isEmpty, line: line)
        guard assertCount(finalised.output, expected: 1, line: line) else { return }
        
        let result = finalised.output[0]
        assertResult(result, g, m, w, t, output, line)
    }
    
    func assertResult(
        _ result: ConditionalActionsResolvingNode.Output,
        _ g: AnyTraceable,
        _ m: Match,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        _ output: String,
        _ line: UInt = #line
    ) {
        XCTAssertEqual(result.state, g, line: line)
        XCTAssertEqual(result.match, m, line: line)
        XCTAssertEqual(result.event, w, line: line)
        XCTAssertEqual(result.nextState, t, line: line)
        
        assertActions(result.actions, expectedOutput: output, line: line)
    }
    
    let m = Match()
    
    func testConditionalDoesNotAddExitActionsWithoutStateChange() {
        assertNode(type: ConditionalActionsResolvingNode.self,
                   g: s1, m: m, w: e1, t: s1, output: "12")
    }
    
    func testUnconditionalAddsExitActionsWithoutStateChange() {
        assertNode(type: ActionsResolvingNode.self,
                   g: s1, m: m, w: e1, t: s1, output: "12>>")
    }
    
    func testConditionalAddsExitActionsWithStateChange() {
        assertNode(type: ConditionalActionsResolvingNode.self,
                   g: s1, m: m, w: e1, t: s2, output: "12>>")
    }
    
    func testConditionalDoesNotAddEntryActionsWithoutStateChange() {
        let d1 = defineNode(s1, m, e1, s1, entry: onEntry, exit: [])
        let result = ConditionalActionsResolvingNode(rest: [d1]).finalised()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 1) else { return }
        
        assertResult(result.output[0], s1, m, e1, s1, "12")
    }
    
    func testUnconditionalAddsEntryActionsWithoutStateChange() {
        let d1 = defineNode(s1, m, e1, s1, entry: onEntry, exit: onExit)
        let result = ActionsResolvingNode(rest: [d1]).finalised()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 1) else { return }
        
        assertResult(result.output[0], s1, m, e1, s1, "12>><<")
    }
    
    func testConditionalAddsEntryActionsForStateChange() {
        let d1 = defineNode(s1, m, e1, s2)
        let d2 = defineNode(s2, m, e1, s3, entry: onEntry, exit: onExit)
        let result = ConditionalActionsResolvingNode(rest: [d1, d2]).finalised()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 2) else { return }
        
        assertResult(result.output[0], s1, m, e1, s2, "12<<")
        assertResult(result.output[1], s2, m, e1, s3, "12>>")
    }
}
