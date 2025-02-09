import XCTest
@testable import SwiftFSM

class ActionsResolvingNodeTests: DefineConsumer {
    func testEmptyNode() {
        let node = ActionsResolvingNode.OnStateChange()
        let finalised = node.resolve()
        XCTAssertTrue(finalised.output.isEmpty)
        XCTAssertTrue(finalised.errors.isEmpty)
    }
    
    func assertNode<T: ActionsResolvingNode>(
        type: T.Type,
        g: AnyTraceable,
        m: MatchDescriptorChain,
        w: AnyTraceable,
        t: AnyTraceable,
        output: String,
        line: UInt = #line
    ) async {
        let node = T.init(rest: [defineNode(g, m, w, t, exit: onExit)])
        let finalised = node.resolve()
        XCTAssertTrue(finalised.errors.isEmpty, line: line)
        guard assertCount(finalised.output, expected: 1, line: line) else { return }
        
        let result = finalised.output[0]
        await assertResult(result, g, m, w, t, output, line)
    }
    
    func assertResult(
        _ result: ActionsResolvingNode.OnStateChange.Output,
        _ g: AnyTraceable,
        _ m: MatchDescriptorChain,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        _ output: String,
        _ line: UInt = #line
    ) async {
        XCTAssertEqual(result.state, g, line: line)
        XCTAssertEqual(result.descriptor, m, line: line)
        XCTAssertEqual(result.event, w, line: line)
        XCTAssertEqual(result.nextState, t, line: line)
        XCTAssertEqual(result.overrideGroupID, testGroupID, line: line)
        XCTAssertEqual(result.isOverride, false, line: line)
        
        await assertActions(result.actions, expectedOutput: output, line: line)
    }
    
    let m = MatchDescriptorChain()
    
    func testConditionalDoesNotAddExitActionsWithoutStateChange() async {
        await assertNode(type: ActionsResolvingNode.OnStateChange.self,
                   g: s1, m: m, w: e1, t: s1, output: "12")
    }
    
    func testUnconditionalAddsExitActionsWithoutStateChange() async {
        await assertNode(type: ActionsResolvingNode.ExecuteAlways.self,
                   g: s1, m: m, w: e1, t: s1, output: "12>>")
    }
    
    func testConditionalAddsExitActionsWithStateChange() async {
        await assertNode(type: ActionsResolvingNode.OnStateChange.self,
                   g: s1, m: m, w: e1, t: s2, output: "12>>")
    }
    
    func testConditionalDoesNotAddEntryActionsWithoutStateChange() async {
        let d1 = defineNode(s1, m, e1, s1, entry: onEntry, exit: [])
        let result = ActionsResolvingNode.OnStateChange(rest: [d1]).resolve()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 1) else { return }
        
        await assertResult(result.output[0], s1, m, e1, s1, "12")
    }
    
    func testUnconditionalAddsEntryActionsWithoutStateChange() async {
        let d1 = defineNode(s1, m, e1, s1, entry: onEntry, exit: onExit)
        let result = ActionsResolvingNode.ExecuteAlways(rest: [d1]).resolve()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 1) else { return }
        
        await assertResult(result.output[0], s1, m, e1, s1, "12>><<")
    }
    
    func testConditionalAddsEntryActionsForStateChange() async {
        let d1 = defineNode(s1, m, e1, s2)
        let d2 = defineNode(s2, m, e1, s3, entry: onEntry, exit: onExit)
        let result = ActionsResolvingNode.OnStateChange(rest: [d1, d2]).resolve()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 2) else { return }
        
        await assertResult(result.output[0], s1, m, e1, s2, "12<<")
        await assertResult(result.output[1], s2, m, e1, s3, "12>>")
    }
}
