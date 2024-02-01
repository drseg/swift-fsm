import XCTest
@testable import SwiftFSM

final class SentenceComponentTests: SyntaxTestsBase {
    func assertMW(_ mw: MatchingWhen<State, Event>, sutLine sl: Int, xctLine xl: UInt = #line) {
        assertMWNode(mw.node, sutLine: sl, xctLine: xl)
    }
    
    func assertMWNode(_ whenNode: WhenNode, sutLine sl: Int, xctLine xl: UInt = #line) {
        let matchNode = whenNode.rest.first as! MatchNode
        
        XCTAssertEqual(1, whenNode.rest.count, line: xl)
        XCTAssertEqual(0, matchNode.rest.count, line: xl)
        
        assertWhenNode(whenNode, sutLine: sl, xctLine: xl)
        assertMatchNode(matchNode, all: [P.a], sutLine: sl, xctLine: xl)
    }
    
    func testMatching() {
        assertMatching(matching(P.a), all: P.a)
        assertMatching(Matching(P.a), all: P.a)

        assertMatching(matching(P.a, or: P.b, line: -1), any: P.a, P.b, sutLine: -1)
        assertMatching(Matching(P.a, or: P.b, line: -1), any: P.a, P.b, sutLine: -1)
        
        assertMatching(matching(P.a, and: Q.a, line: -1), all: P.a, Q.a, sutLine: -1)
        assertMatching(Matching(P.a, and: Q.a, line: -1), all: P.a, Q.a, sutLine: -1)
        
        assertMatching(matching(P.a, or: P.b, and: Q.a, R.a, line: -1), 
                       any: P.a, P.b, all: Q.a, R.a, sutLine: -1)
        assertMatching(Matching(P.a, or: P.b, and: Q.a, R.a, line: -1), 
                       any: P.a, P.b, all: Q.a, R.a, sutLine: -1)
    }
    
    func testCondition() {
        assertCondition(condition({ true }), expected: true)
        assertCondition(Condition({ true }), expected: true)
    }
            
    func testWhen() {
        assertWhen(when(1, or: 2))
        assertWhen(When(1, or: 2))
        assertWhen(when(1), events: [1])
        assertWhen(When(1), events: [1])
    }
    
    func testThen() {
        assertThen(then(1), sutFile: #file)
        assertThen(Then(1), sutFile: #file)
        assertThen(then(), state: nil, sutLine: nil)
        assertThen(Then(), state: nil, sutLine: nil)
    }
    
    func testMatchingWhen() {
        assertMW(matching(P.a) | when(1, or: 2), sutLine: #line)
        assertMW(Matching(P.a) | When(1, or: 2), sutLine: #line)
    }
    
    func testMatchingWhenThen() {
        func assertMWT(_ mwt: MatchingWhenThen<Event>, sutLine sl: Int, xctLine xl: UInt = #line) {
            let then = mwt.node
            let when = then.rest.first as! WhenNode
            
            XCTAssertEqual(1, then.rest.count, line: xl)
            assertThenNode(then, state: 1, sutFile: #file, sutLine: sl, xctLine: xl)
            assertMWNode(when, sutLine: sl)
        }
        
        assertMWT(matching(P.a) | when(1, or: 2) | then(1), sutLine: #line)
        assertMWT(Matching(P.a) | When(1, or: 2) | Then(1), sutLine: #line)
    }
    
    func testMatchingWhenThenActions() {
        let mwta1 = matching(P.a) | when(1, or: 2) | then(1) | pass; let l1 = #line
        let mwta2 = Matching(P.a) | When(1, or: 2) | Then(1) | pass; let l2 = #line

        assertMWTA(mwta1.node, sutLine: l1)
        assertMWTA(mwta2.node, sutLine: l2)
    }

    func testMatchingWhenThenActions_withEvent() {
        let mwta1 = Matching(P.a) | When(1, or: 2) | Then(1) | passWithEvent; let l1 = #line
        let mwta2 = matching(P.a) | when(1, or: 2) | then(1) | passWithEvent; let l2 = #line

        assertMWTA(mwta1.node, event: 111, expectedOutput: "pass, event: 111", sutLine: l1)
        assertMWTA(mwta2.node, event: 111, expectedOutput: "pass, event: 111", sutLine: l2)
    }

    func testMatchingWhenThenActionsAsync() {
        let mwta1 = matching(P.a) | when(1, or: 2) | then(1) | passAsync; let l1 = #line
        let mwta2 = Matching(P.a) | When(1, or: 2) | Then(1) | passAsync; let l2 = #line

        assertMWTA(mwta1.node, sutLine: l1)
        assertMWTA(mwta2.node, sutLine: l2)
    }

    func testMatchingWhenThenActionsAsync_withEvent() {
        let mwta1 = Matching(P.a) | When(1, or: 2) | Then(1) | passWithEventAsync; let l1 = #line
        let mwta2 = matching(P.a) | when(1, or: 2) | then(1) | passWithEventAsync; let l2 = #line

        assertMWTA(mwta1.node, event: 111, expectedOutput: "pass, event: 111", sutLine: l1)
        assertMWTA(mwta2.node, event: 111, expectedOutput: "pass, event: 111", sutLine: l2)
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
        assertWT(When(1, or: 2) | Then(1), sutLine: #line)
    }
    
    func testWhenThenActions() {
        let wta1 = when(1, or: 2) | then(1) | pass; let l1 = #line
        let wta2 = When(1, or: 2) | Then(1) | pass; let l2 = #line
        
        assertWTA(wta1.node, sutLine: l1)
        assertWTA(wta2.node, sutLine: l2)
    }

    func testWhenThenActionsAsync() {
        let wta1 = when(1, or: 2) | then(1) | passAsync; let l1 = #line
        let wta2 = When(1, or: 2) | Then(1) | passAsync; let l2 = #line

        assertWTA(wta1.node, sutLine: l1)
        assertWTA(wta2.node, sutLine: l2)
    }

    func testWhenThenActions_withEvent() {
        let wta1 = When(1, or: 2) | Then(1) | passWithEvent; let l1 = #line
        let wta2 = when(1, or: 2) | then(1) | passWithEvent; let l2 = #line

        assertWTA(wta1.node, expectedOutput: Self.defaultOutputWithEvent, sutLine: l1)
        assertWTA(wta2.node, expectedOutput: Self.defaultOutputWithEvent, sutLine: l2)
    }

    func testWhenThenActionsAsync_withEvent() {
        let wta1 = When(1, or: 2) | Then(1) | passWithEventAsync; let l1 = #line
        let wta2 = when(1, or: 2) | then(1) | passWithEventAsync; let l2 = #line

        assertWTA(wta1.node, expectedOutput: Self.defaultOutputWithEvent, sutLine: l1)
        assertWTA(wta2.node, expectedOutput: Self.defaultOutputWithEvent, sutLine: l2)
    }
}
