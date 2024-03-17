import XCTest
@testable import SwiftFSM

final class SentenceComponentTests: SyntaxTestsBase {
    @MainActor
    func assertMW(_ mw: MatchingWhen<State, Event>, sutLine sl: Int, xctLine xl: UInt = #line) {
        assertMWNode(mw.node, sutLine: sl, xctLine: xl)
    }
    
    @MainActor
    func assertMWNode(_ whenNode: WhenNode, sutLine sl: Int, xctLine xl: UInt = #line) {
        let matchNode = whenNode.rest.first as! MatchNode
        
        XCTAssertEqual(1, whenNode.rest.count, line: xl)
        XCTAssertEqual(0, matchNode.rest.count, line: xl)
        
        assertWhenNode(whenNode, sutLine: sl, xctLine: xl)
        assertMatchNode(matchNode, all: [P.a], sutLine: sl, xctLine: xl)
    }
    
    @MainActor
    func testMatching() {
        assertMatching(matching(P.a), all: P.a)
        assertMatching(matching(P.a, or: P.b, line: -1), any: P.a, P.b, sutLine: -1)
        assertMatching(matching(P.a, and: Q.a, line: -1), all: P.a, Q.a, sutLine: -1)
        assertMatching(matching(P.a, or: P.b, and: Q.a, R.a, line: -1),
                       any: P.a, P.b, all: Q.a, R.a, sutLine: -1)
    }
    
    @MainActor
    func testCondition() {
        assertCondition(condition({ true }), expected: true)
    }
            
    func testWhen() {
        assertWhen(when(1, or: 2))
        assertWhen(when(1), events: [1])
    }
    
    func testThen() {
        assertThen(then(1), sutFile: #file)
        assertThen(then(), state: nil, sutLine: nil)
    }
    
    @MainActor
    func testMatchingWhen() {
        assertMW(matching(P.a) | when(1, or: 2), sutLine: #line)
    }

    @MainActor
    func testMatchingWhenThen() {
        func assertMWT(_ mwt: MatchingWhenThen<Event>, sutLine sl: Int, xctLine xl: UInt = #line) {
            let then = mwt.node
            let when = then.rest.first as! WhenNode
            
            XCTAssertEqual(1, then.rest.count, line: xl)
            assertThenNode(then, state: 1, sutFile: #file, sutLine: sl, xctLine: xl)
            assertMWNode(when, sutLine: sl)
        }
        
        assertMWT(matching(P.a) | when(1, or: 2) | then(1), sutLine: #line)
    }
    
    @MainActor
    func testMatchingWhenThenActions() {
        let mwta1 = matching(P.a) | when(1, or: 2) | then(1) | pass; let l1 = #line
        let mwta2 = matching(P.a) | when(1, or: 2) | then(1) | pass & pass; let l2 = #line

        assertMWTA(mwta1.node, sutLine: l1)
        assertMWTA(mwta2.node,
                   expectedOutput: Self.defaultOutput + Self.defaultOutput,
                   sutLine: l2)
    }

    @MainActor
    func testMatchingWhenThenActions_withEvent() {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passWithEvent; let l2 = #line
        assertMWTA(mwta.node, event: 111, expectedOutput: "pass, event: 111", sutLine: l2)
    }

    @MainActor
    func testMatchingWhenThenActionsAsync() {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passAsync; let l1 = #line
        assertMWTA(mwta.node, sutLine: l1)
    }

    @MainActor
    func testMatchingWhenThenActionsAsync_withEvent() {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passWithEventAsync; let l2 = #line
        assertMWTA(mwta.node, event: 111, expectedOutput: "pass, event: 111", sutLine: l2)
    }

    func testWhenThen() {
        func assertWT(_ wt: MatchingWhenThen<Event>, sutLine sl: Int, xctLine xl: UInt = #line) {
            let then = wt.node
            let when = then.rest.first as! WhenNode

            XCTAssertEqual(1, then.rest.count, line: xl)
            XCTAssertEqual(0, when.rest.count, line: xl)

            assertThenNode(then, state: 1, sutFile: #file, sutLine: sl, xctLine: xl)
            assertWhenNode(when, sutLine: sl, xctLine: xl)
        }

        assertWT(when(1, or: 2) | then(1), sutLine: #line)
    }
    
    func testWhenThenActions() {
        let wta1 = when(1, or: 2) | then(1) | pass; let l1 = #line
        let wta2 = when(1, or: 2) | then(1) | pass & pass; let l2 = #line

        assertWTA(wta1.node, sutLine: l1)
        assertWTA(wta2.node, expectedOutput: Self.defaultOutput + Self.defaultOutput, sutLine: l2)
    }

    func testWhenThenActionsAsync() {
        let wta1 = when(1, or: 2) | then(1) | passAsync; let l1 = #line
        assertWTA(wta1.node, sutLine: l1)
    }

    func testWhenThenActions_withEvent() {
        let wta2 = when(1, or: 2) | then(1) | passWithEvent; let l2 = #line
        assertWTA(wta2.node, expectedOutput: Self.defaultOutputWithEvent, sutLine: l2)
    }

    func testWhenThenActionsAsync_withEvent() {
        let wta2 = when(1, or: 2) | then(1) | passWithEventAsync; let l2 = #line
        assertWTA(wta2.node, expectedOutput: Self.defaultOutputWithEvent, sutLine: l2)
    }
}
