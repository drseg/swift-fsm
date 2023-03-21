//
//  File.swift
//  
//
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

final class ComponentTests: SyntaxTestsBase {
    func assertMW(_ mw: MatchingWhen, sutLine sl: Int, xctLine xl: UInt = #line) {
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
        let m1 = matching(P.a); let l1 = #line
        let m2 = Matching(P.a); let l2 = #line
        
        assertMatching(m1, all: P.a, sutLine: l1)
        assertMatching(m2, all: P.a, sutLine: l2)
        
        let m3 = matching(any: P.a, P.b, line: -1)
        let m4 = Matching(any: P.a, P.b, line: -1)

        assertMatching(m3, any: P.a, P.b, sutLine: -1)
        assertMatching(m4, any: P.a, P.b, sutLine: -1)
        
        let m5 = matching(all: P.a, Q.a, line: -1)
        let m6 = Matching(all: P.a, Q.a, line: -1)
        
        assertMatching(m5, all: P.a, Q.a, sutLine: -1)
        assertMatching(m6, all: P.a, Q.a, sutLine: -1)
        
        let m7 = matching(any: P.a, P.b, all: Q.a, R.a, line: -1)
        let m8 = Matching(any: P.a, P.b, all: Q.a, R.a, line: -1)
        
        assertMatching(m7, any: P.a, P.b, all: Q.a, R.a, sutLine: -1)
        assertMatching(m8, any: P.a, P.b, all: Q.a, R.a, sutLine: -1)
    }
            
    func testWhen() {
        let w1 = when(1, 2); let l1 = #line
        let w2 = When(1, 2); let l2 = #line
        
        assertWhen(w1, sutLine: l1)
        assertWhen(w2, sutLine: l2)
    }
    
    func testThen() {
        let n1 = then(1).node; let l1 = #line
        let n2 = Then(1).node; let l2 = #line
        
        let n3 = then().node
        let n4 = Then().node
        
        assertThenNode(n1, state: 1, sutFile: #file, sutLine: l1)
        assertThenNode(n2, state: 1, sutFile: #file, sutLine: l2)

        assertThenNode(n3, state: nil, sutLine: nil)
        assertThenNode(n4, state: nil, sutLine: nil)
    }
    
    func testMatchingWhen() {
        assertMW(matching(P.a) | when(1, 2), sutLine: #line)
        assertMW(Matching(P.a) | When(1, 2), sutLine: #line)
    }
    
    func testMatchingWhenThen() {
        func assertMWT(_ mwt: MatchingWhenThen, sutLine sl: Int, xctLine xl: UInt = #line) {
            let then = mwt.node
            let when = then.rest.first as! WhenNode
            
            XCTAssertEqual(1, then.rest.count, line: xl)
            assertThenNode(then, state: 1, sutFile: #file, sutLine: sl, xctLine: xl)
            assertMWNode(when, sutLine: sl)
        }
        
        assertMWT(matching(P.a) | when(1, 2) | then(1), sutLine: #line)
        assertMWT(Matching(P.a) | When(1, 2) | Then(1), sutLine: #line)
    }
    
    func testMatchingWhenThenActions() {
        let mwta1 = matching(P.a) | when(1, 2) | then(1) | pass; let l1 = #line
        let mwta2 = Matching(P.a) | When(1, 2) | Then(1) | pass; let l2 = #line

        assertMWTA(mwta1.node, sutLine: l1)
        assertMWTA(mwta2.node, sutLine: l2)
    }
    
    func testWhenThen() {
        func assertWT(_ wt: MatchingWhenThen, sutLine sl: Int, xctLine xl: UInt = #line) {
            let then = wt.node
            let when = then.rest.first as! WhenNode

            XCTAssertEqual(1, then.rest.count, line: xl)
            XCTAssertEqual(0, when.rest.count, line: xl)

            assertThenNode(then, state: 1, sutFile: #file, sutLine: sl, xctLine: xl)
            assertWhenNode(when, sutLine: sl, xctLine: xl)
        }

        assertWT(when(1, 2) | then(1), sutLine: #line)
        assertWT(When(1, 2) | Then(1), sutLine: #line)
    }
    
    func testWhenThenActions() {
        let wta1 = when(1, 2) | then(1) | pass; let l1 = #line
        let wta2 = When(1, 2) | Then(1) | pass; let l2 = #line
        
        assertWTA(wta1.node, sutLine: l1)
        assertWTA(wta2.node, sutLine: l2)
    }
}
