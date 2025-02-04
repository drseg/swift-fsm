import XCTest
@testable import SwiftFSM

final class CompoundSyntaxTests: SyntaxTestsBase {
    func assertMW(
        _ mw: MatchingWhen<State, Event>,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        await assertMWNode(mw.node, sutLine: sl, xctLine: xl)
    }
    
    func assertMWNode<N: Node>(_ n: N, sutLine sl: Int, xctLine xl: UInt = #line) async{
        let whenNode = n as! WhenNode
        let matchNode = n.rest.first as! MatchingNode
        
        XCTAssertEqual(1, whenNode.rest.count, line: xl)
        XCTAssertEqual(0, matchNode.rest.count, line: xl)
        
        assertWhenNode(whenNode, sutLine: sl, xctLine: xl)
        await assertMatchNode(matchNode, all: [P.a], sutLine: sl, xctLine: xl)
    }
    
    func testMatching() async {
        await assertMatching(matching(P.a), all: P.a)
        await assertMatching(matching(P.a, or: P.b, line: -1), any: P.a, P.b, sutLine: -1)
        await assertMatching(matching(P.a, and: Q.a, line: -1), all: P.a, Q.a, sutLine: -1)
        await assertMatching(matching(P.a, or: P.b, and: Q.a, R.a, line: -1),
                             any: P.a, P.b, all: Q.a, R.a, sutLine: -1)
    }
    
    func testCondition() async {
        await assertCondition(condition({ true }), expected: true)
    }
            
    func testWhen() {
        assertWhen(when(1, or: 2))
        assertWhen(when(1), events: [1])
    }
    
    func testThen() {
        assertThen(then(1), sutFile: #file)
        assertThen(then(), state: nil, sutLine: nil)
    }
    
    func testMatchingWhen() async {
        await assertMW(matching(P.a) | when(1, or: 2), sutLine: #line)
    }

    func testMatchingWhenThen() async {
        func assertMWT(
            _ mwt: MatchingWhenThen<Event>,
            sutLine sl: Int,
            xctLine xl: UInt = #line
        ) async {
            let then = mwt.node
            let when = then.rest.first as! WhenNode
            
            XCTAssertEqual(1, then.rest.count, line: xl)
            assertThenNode(then as! ThenNodeBase, state: 1, sutFile: #file, sutLine: sl, xctLine: xl)
            await assertMWNode(when, sutLine: sl)
        }
        
        await assertMWT(matching(P.a) | when(1, or: 2) | then(1), sutLine: #line)
    }
    
    func testMatchingWhenThenActions() async {
        let mwta1 = matching(P.a) | when(1, or: 2) | then(1) | pass; let l1 = #line
        let mwta2 = matching(P.a) | when(1, or: 2) | then(1) | pass & pass; let l2 = #line

        await assertMWTA(mwta1.node, sutLine: l1)
        await assertMWTA(mwta2.node,
                   expectedOutput: Self.defaultOutput + Self.defaultOutput,
                   sutLine: l2)
    }

    func testMatchingWhenThenActions_withEvent() async {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passWithEvent; let l2 = #line
        await assertMWTA(mwta.node, event: 111, expectedOutput: "pass, event: 111", sutLine: l2)
    }

    func testMatchingWhenThenActionsAsync() async {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passAsync; let l1 = #line
        await assertMWTA(mwta.node, sutLine: l1)
    }

    func testMatchingWhenThenActionsAsync_withEvent() async {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passWithEventAsync; let l2 = #line
        await assertMWTA(mwta.node, event: 111, expectedOutput: "pass, event: 111", sutLine: l2)
    }

    func testWhenThen() {
        func assertWT(_ wt: MatchingWhenThen<Event>, sutLine sl: Int, xctLine xl: UInt = #line) {
            let then = wt.node
            let when = then.rest.first as! WhenNode

            XCTAssertEqual(1, then.rest.count, line: xl)
            XCTAssertEqual(0, when.rest.count, line: xl)

            assertThenNode(then as! ThenNodeBase, state: 1, sutFile: #file, sutLine: sl, xctLine: xl)
            assertWhenNode(when, sutLine: sl, xctLine: xl)
        }

        assertWT(when(1, or: 2) | then(1), sutLine: #line)
    }
    
    func testWhenThenActions() async {
        let wta1 = when(1, or: 2) | then(1) | pass; let l1 = #line
        let wta2 = when(1, or: 2) | then(1) | pass & pass; let l2 = #line

        await assertWTA(wta1.node, sutLine: l1)
        await assertWTA(
            wta2.node,
            expectedOutput: Self.defaultOutput + Self.defaultOutput,
            sutLine: l2
        )
    }

    func testWhenThenActionsAsync() async {
        let wta1 = when(1, or: 2) | then(1) | passAsync; let l1 = #line
        await assertWTA(wta1.node, sutLine: l1)
    }

    func testWhenThenActions_withEvent() async {
        let wta2 = when(1, or: 2) | then(1) | passWithEvent; let l2 = #line
        await assertWTA(wta2.node, expectedOutput: Self.defaultOutputWithEvent, sutLine: l2)
    }

    func testWhenThenActionsAsync_withEvent() async {
        let wta2 = when(1, or: 2) | then(1) | passWithEventAsync; let l2 = #line
        await assertWTA(wta2.node, expectedOutput: Self.defaultOutputWithEvent, sutLine: l2)
    }
}
